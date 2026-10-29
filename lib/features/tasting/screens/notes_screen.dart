import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../wines/models/wine.dart';
import '../../wines/providers/wines_providers.dart';
import '../../wines/widgets/rating_stars.dart';
import '../../wines/widgets/wine_avatar.dart';
import '../models/note_filter.dart';
import '../models/taste_attr.dart';
import '../models/tasting_note.dart';
import '../providers/tasting_providers.dart';
import '../widgets/label_photo.dart';
import '../widgets/taste_profile_view.dart';

/// 노트 탭의 검색·필터·모아보기 상태 (탭을 옮겨도 유지).
final noteFilterProvider = StateProvider<NoteFilter>((_) => const NoteFilter());

final _winesByIdProvider = Provider<Map<String, Wine>>(
  (ref) => {for (final w in ref.watch(visibleWinesProvider)) w.id: w},
);

/// 전체 테이스팅 노트 — 검색, 생산자·빈티지·품종·국가·지역·종류 필터, 모아보기.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  late final _search =
      TextEditingController(text: ref.read(noteFilterProvider).query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickFacet(
    NoteFacet facet,
    List<TastingNote> notes,
    Map<String, Wine> winesById,
  ) async {
    final counts = facetCounts(facet, notes, winesById);
    final current = ref.read(noteFilterProvider).selected[facet] ?? const {};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FacetSheet(
        facet: facet,
        values: sortedFacetValues(facet, counts),
        counts: counts,
        initial: current,
      ),
    );
    if (result == null) return;
    final f = ref.read(noteFilterProvider);
    ref.read(noteFilterProvider.notifier).state =
        f.withSelection(facet, result);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(visibleNotesProvider);
    final winesById = ref.watch(_winesByIdProvider);
    final filter = ref.watch(noteFilterProvider);
    final notes = filter.apply(all, winesById);
    final theme = Theme.of(context);

    Widget tile(TastingNote n) => _NoteTile(note: n, wine: winesById[n.wineId]);

    final groupBy = filter.groupBy;
    final List<Widget> items;
    if (groupBy == null) {
      items = [
        for (final n in notes) ...[tile(n), const Divider(height: 1)],
      ];
    } else {
      items = [
        for (final g in groupNotes(groupBy, notes, winesById))
          ExpansionTile(
            initiallyExpanded: true,
            title: Text('${g.key} (${g.value.length})'),
            children: [for (final n in g.value) tile(n)],
          ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('테이스팅 노트'),
        actions: [
          // 메뉴 값이 null 이면 onSelected 가 불리지 않으므로 인덱스(-1 = 없음)를 쓴다.
          PopupMenuButton<int>(
            tooltip: '모아보기',
            icon: Icon(
              Icons.workspaces_outline,
              color: groupBy == null ? null : theme.colorScheme.primary,
            ),
            onSelected: (i) => ref.read(noteFilterProvider.notifier).state =
                filter.copyWith(groupBy: i < 0 ? null : NoteFacet.values[i]),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: -1,
                checked: groupBy == null,
                child: const Text('모아보기 없음 (시음일순)'),
              ),
              for (final f in NoteFacet.values)
                CheckedPopupMenuItem(
                  value: f.index,
                  checked: groupBy == f,
                  child: Text('${f.label}별로 모아보기'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.freshNote),
        icon: const Icon(Icons.add),
        label: const Text('새 노트'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (t) => ref.read(noteFilterProvider.notifier).state =
                  ref.read(noteFilterProvider).copyWith(query: t),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '와인 이름·생산자·총평·키워드 검색',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (filter.isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.filter_alt_off, size: 18),
                      label: const Text('초기화'),
                      onPressed: () {
                        _search.clear();
                        ref.read(noteFilterProvider.notifier).state =
                            filter.cleared();
                      },
                    ),
                  ),
                for (final f in NoteFacet.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_chipLabel(f, filter.selected[f])),
                      selected: filter.selected[f]?.isNotEmpty ?? false,
                      showCheckmark: false,
                      onSelected: (_) => _pickFacet(f, all, winesById),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? const _Empty()
                : notes.isEmpty
                    ? const Center(child: Text('조건에 맞는 노트가 없습니다.'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Text(
                              filter.isActive
                                  ? '${notes.length}개 / 전체 ${all.length}개'
                                  : '${notes.length}개',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          if (groupBy == NoteFacet.grape)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '블렌드 와인의 노트는 들어간 품종마다 표시됩니다.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ...items,
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  static String _chipLabel(NoteFacet f, Set<String>? sel) {
    if (sel == null || sel.isEmpty) return f.label;
    if (sel.length == 1) return '${f.label}: ${sel.first}';
    return '${f.label} ${sel.length}';
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.wine});

  final TastingNote note;
  final Wine? wine;

  @override
  Widget build(BuildContext context) {
    final n = note;
    final w = wine;
    final profile = averageProfile([n]);
    final line2 = [
      DateFormat('yyyy.MM.dd', 'ko_KR').format(n.tastedAt),
      if (w != null && w.producer.isNotEmpty) w.producer,
      if (w != null && w.country.isNotEmpty) w.country,
      if (w != null && w.grapes.isNotEmpty)
        w.isBlend ? '블렌드(${w.grapes.join('·')})' : w.grapes.first,
    ].join(' · ');
    final line3 = [
      if (profile.isNotEmpty) profileSummary(profile, max: 3),
      if (n.comment.isNotEmpty) n.comment,
    ].join(' — ');

    return ListTile(
      onTap: () => context.push(Routes.note(n.id)),
      leading: n.photos.isNotEmpty
          ? LabelPhoto(path: n.photos.first, size: 48)
          : (w == null ? null : WineAvatar(wine: w, size: 48)),
      title: Text(
        w == null ? '(삭제된 와인)' : '${w.name} ${w.vintageLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        line3.isEmpty ? line2 : '$line2\n$line3',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(ratingText(n.rating)),
    );
  }
}

/// 기준 하나의 값 다중 선택 시트.
class _FacetSheet extends StatefulWidget {
  const _FacetSheet({
    required this.facet,
    required this.values,
    required this.counts,
    required this.initial,
  });

  final NoteFacet facet;
  final List<String> values;
  final Map<String, int> counts;
  final Set<String> initial;

  @override
  State<_FacetSheet> createState() => _FacetSheetState();
}

class _FacetSheetState extends State<_FacetSheet> {
  late final Set<String> _sel = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.facet.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(_sel.clear),
                  child: const Text('선택 해제'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _sel),
                  child: const Text('적용'),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.values.isEmpty
                ? const Center(child: Text('노트가 없습니다.'))
                : ListView(
                    children: [
                      for (final v in widget.values)
                        CheckboxListTile(
                          dense: true,
                          value: _sel.contains(v),
                          title: Text('$v (${widget.counts[v]})'),
                          onChanged: (on) => setState(
                            () => on == true ? _sel.add(v) : _sel.remove(v),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          '아직 작성한 노트가 없습니다.\n아래 "새 노트"로 마신 와인을 기록해 보세요.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
