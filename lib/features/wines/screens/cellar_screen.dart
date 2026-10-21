import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../tasting/providers/tasting_providers.dart';
import '../models/wine.dart';
import '../providers/wines_providers.dart';
import '../widgets/wine_tile.dart';

enum _Sort { recent, rating, name }

/// 내 와인 (셀러) — 전체 / 즐겨찾기.
class CellarScreen extends ConsumerStatefulWidget {
  const CellarScreen({super.key});

  @override
  ConsumerState<CellarScreen> createState() => _CellarScreenState();
}

class _CellarScreenState extends ConsumerState<CellarScreen> {
  bool _favoritesOnly = false;
  _Sort _sort = _Sort.recent;

  List<Wine> _apply(List<Wine> all) {
    final list =
        _favoritesOnly ? all.where((w) => w.isFavorite).toList() : [...all];
    switch (_sort) {
      case _Sort.recent:
        break; // provider already sorts by updatedAt desc
      case _Sort.rating:
        list.sort((a, b) => (b.myRating ?? -1).compareTo(a.myRating ?? -1));
      case _Sort.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final wines = _apply(ref.watch(visibleWinesProvider));
    final notes = ref.watch(visibleNotesProvider);
    final noteCounts = <String, int>{};
    for (final n in notes) {
      noteCounts[n.wineId] = (noteCounts[n.wineId] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 와인'),
        actions: [
          PopupMenuButton<_Sort>(
            tooltip: '정렬',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.recent, child: Text('최근 수정순')),
              PopupMenuItem(value: _Sort.rating, child: Text('내 평점순')),
              PopupMenuItem(value: _Sort.name, child: Text('이름순')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newWine),
        icon: const Icon(Icons.add),
        label: const Text('직접 추가'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('전체')),
                  ButtonSegment(
                    value: true,
                    label: Text('즐겨찾기'),
                    icon: Icon(Icons.favorite, size: 16),
                  ),
                ],
                selected: {_favoritesOnly},
                onSelectionChanged: (s) =>
                    setState(() => _favoritesOnly = s.first),
              ),
            ),
          ),
          Expanded(
            child: wines.isEmpty
                ? _Empty(favoritesOnly: _favoritesOnly)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: wines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final w = wines[i];
                      return WineTile(
                        wine: w,
                        noteCount: noteCounts[w.id] ?? 0,
                        onTap: () => context.push(Routes.wine(w.id)),
                        onToggleFavorite: () => ref
                            .read(winesProvider.notifier)
                            .toggleFavorite(w.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wine_bar_outlined,
                size: 56, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(
              favoritesOnly ? '즐겨찾기한 와인이 없습니다.' : '아직 저장한 와인이 없습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go(Routes.search),
              icon: const Icon(Icons.search),
              label: const Text('와인 검색하기'),
            ),
          ],
        ),
      ),
    );
  }
}
