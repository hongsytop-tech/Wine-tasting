import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../search/models/wine_search_result.dart';
import '../../tasting/models/taste_attr.dart';
import '../../tasting/models/tasting_note.dart';
import '../../tasting/providers/tasting_providers.dart';
import '../../tasting/widgets/taste_profile_view.dart';
import '../models/wine.dart';
import '../providers/wines_providers.dart';
import '../widgets/rating_stars.dart';
import '../widgets/wine_thumb.dart';

class WineDetailScreen extends ConsumerWidget {
  const WineDetailScreen({super.key, required this.wineId});

  final String wineId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Wine w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('와인 삭제'),
        content: Text('"${w.name}" 과(와) 테이스팅 노트를 모두 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tastingNotesProvider.notifier).deleteForWine(w.id);
    await ref.read(winesProvider.notifier).delete(w.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wine = ref.watch(wineByIdProvider(wineId));
    if (wine == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('와인을 찾을 수 없습니다.')),
      );
    }
    final notes = ref.watch(notesForWineProvider(wineId));
    final tasting = ref.watch(tastingSummaryProvider)[wineId];
    final theme = Theme.of(context);
    final notifier = ref.read(winesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: wine.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
            icon: Icon(
              wine.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: wine.isFavorite ? theme.colorScheme.primary : null,
            ),
            onPressed: () => notifier.toggleFavorite(wine.id),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') context.push(Routes.editWine(wine.id));
              if (v == 'delete') _delete(context, ref, wine);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('정보 수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newNote(wine.id)),
        icon: const Icon(Icons.edit_note),
        label: const Text('마신 기록 · 평가'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WineThumb(imageUrl: wine.imageUrl, type: wine.type, size: 96),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wine.name, style: theme.textTheme.titleLarge),
                    if (wine.producer.isNotEmpty)
                      Text(wine.producer, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('${wine.vintageLabel} · ${wine.type.label}'),
                    if (wine.originLabel.isNotEmpty) Text(wine.originLabel),
                    if (wine.grapes.isNotEmpty) Text(wine.grapes.join(', ')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('내 평점', style: theme.textTheme.labelLarge),
          Row(
            children: [
              RatingStars(
                value: wine.myRating,
                size: 36,
                onChanged: (v) => notifier.setRating(wine.id, v),
              ),
              const SizedBox(width: 8),
              Text(ratingText(wine.myRating),
                  style: theme.textTheme.titleMedium),
            ],
          ),
          if (wine.memo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('메모', style: theme.textTheme.labelLarge),
            Text(wine.memo),
          ],
          if (wine.source != 'manual') ...[
            const SizedBox(height: 12),
            _SourceLink(wine: wine),
          ],
          const Divider(height: 32),
          if (tasting != null) ...[
            _TastingSection(summary: tasting),
            const Divider(height: 32),
          ],
          Text('테이스팅 노트 (${notes.length})', style: theme.textTheme.titleMedium),
          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '아직 마신 기록이 없습니다. 아래 버튼으로 평가(색·당도·타닌·산미 등 0~10점)를 남겨 보세요.',
              ),
            ),
          for (final n in notes) _NoteTile(note: n),
        ],
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.wine});

  final Wine wine;

  @override
  Widget build(BuildContext context) {
    final label = '출처: ${sourceLabel(wine.source)}';
    if (wine.sourceUrl.isEmpty) {
      return Text(label, style: Theme.of(context).textTheme.bodySmall);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () => launchUrl(
          Uri.parse(wine.sourceUrl),
          mode: LaunchMode.externalApplication,
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(label),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final TastingNote note;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(note.tastedAt);
    final summary = [
      if (averageProfile([note]).isNotEmpty)
        profileSummary(averageProfile([note])),
      if (note.aromas.isNotEmpty) note.aromas.take(4).join(', '),
      if (note.comment.isNotEmpty) note.comment,
    ].join(' — ');
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        onTap: () => context.push(Routes.note(note.id)),
        title: Row(
          children: [
            Expanded(child: Text(date)),
            RatingStars(value: note.rating, size: 16),
          ],
        ),
        subtitle: summary.isEmpty
            ? null
            : Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// 마신 기록 요약 + 특징 점수(0~10) 프로필.
class _TastingSection extends StatelessWidget {
  const _TastingSection({required this.summary});

  final WineTastingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    final info = [
      '${s.count}회 마심',
      '마지막 ${DateFormat('yyyy.MM.dd').format(s.lastTastedAt)}',
      if (s.avgRating != null) '노트 평균 평점 ${scoreText(s.avgRating!)}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('마신 기록', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(info),
        const SizedBox(height: 12),
        Text(
          s.count > 1 ? '특징 (0~10점, 노트 ${s.count}개의 평균)' : '특징 (0~10점)',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        if (s.profile.isEmpty)
          Text(
            '노트에 특징 점수가 아직 없습니다.',
            style: theme.textTheme.bodySmall,
          )
        else
          TasteProfileView(values: s.profile),
      ],
    );
  }
}
