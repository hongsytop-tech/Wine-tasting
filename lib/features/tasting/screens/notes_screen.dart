import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../wines/providers/wines_providers.dart';
import '../../wines/widgets/rating_stars.dart';
import '../../wines/widgets/wine_thumb.dart';
import '../providers/tasting_providers.dart';

/// 전체 테이스팅 노트 — 시음일 최신순.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(visibleNotesProvider);
    final fmt = DateFormat('yyyy.MM.dd', 'ko_KR');

    return Scaffold(
      appBar: AppBar(title: const Text('테이스팅 노트')),
      body: notes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '아직 작성한 노트가 없습니다.\n내 와인에서 와인을 열고 "테이스팅 노트"를 눌러 작성하세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = notes[i];
                final wine = ref.watch(wineByIdProvider(n.wineId));
                final summary = [
                  if (n.aromas.isNotEmpty) n.aromas.take(3).join(', '),
                  if (n.comment.isNotEmpty) n.comment,
                ].join(' — ');
                return ListTile(
                  onTap: () => context.push(Routes.note(n.id)),
                  leading: wine == null
                      ? null
                      : WineThumb(
                          imageUrl: wine.imageUrl, type: wine.type, size: 44),
                  title: Text(
                    wine == null
                        ? '(삭제된 와인)'
                        : '${wine.name} ${wine.vintageLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [fmt.format(n.tastedAt), if (summary.isNotEmpty) summary]
                        .join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(ratingText(n.rating)),
                );
              },
            ),
    );
  }
}
