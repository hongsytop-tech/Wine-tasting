import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../tasting/providers/tasting_providers.dart';
import '../models/wine.dart';
import '../providers/wines_providers.dart';
import '../widgets/wine_tile.dart';

enum _Filter { all, favorites, tasted }

enum _Sort { recent, tasted, rating, name }

/// 내 와인 (셀러) — 전체 / 즐겨찾기 / 마신 와인(테이스팅 노트가 있는 와인).
class CellarScreen extends ConsumerStatefulWidget {
  const CellarScreen({super.key});

  @override
  ConsumerState<CellarScreen> createState() => _CellarScreenState();
}

class _CellarScreenState extends ConsumerState<CellarScreen> {
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.recent;

  List<Wine> _apply(
    List<Wine> all,
    Map<String, WineTastingSummary> tasting,
  ) {
    final list = switch (_filter) {
      _Filter.all => [...all],
      _Filter.favorites => all.where((w) => w.isFavorite).toList(),
      _Filter.tasted => all.where((w) => tasting.containsKey(w.id)).toList(),
    };
    switch (_sort) {
      case _Sort.recent:
        break; // provider already sorts by updatedAt desc
      case _Sort.tasted:
        // 마신 와인 먼저 (최근 시음순), 안 마신 와인은 뒤로.
        final never = DateTime.fromMillisecondsSinceEpoch(0);
        list.sort(
          (a, b) => (tasting[b.id]?.lastTastedAt ?? never)
              .compareTo(tasting[a.id]?.lastTastedAt ?? never),
        );
      case _Sort.rating:
        list.sort((a, b) => (b.myRating ?? -1).compareTo(a.myRating ?? -1));
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return list;
  }

  void _setFilter(_Filter f) => setState(() {
        _filter = f;
        // "마신 와인"은 기본으로 최근 시음순이 자연스럽다.
        if (f == _Filter.tasted && _sort == _Sort.recent) _sort = _Sort.tasted;
      });

  @override
  Widget build(BuildContext context) {
    final tasting = ref.watch(tastingSummaryProvider);
    final wines = _apply(ref.watch(visibleWinesProvider), tasting);

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
              PopupMenuItem(value: _Sort.tasted, child: Text('최근 시음순')),
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
              child: SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Filter.all, label: Text('전체')),
                  ButtonSegment(value: _Filter.favorites, label: Text('즐겨찾기')),
                  ButtonSegment(value: _Filter.tasted, label: Text('마신 와인')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => _setFilter(s.first),
              ),
            ),
          ),
          Expanded(
            child: wines.isEmpty
                ? _Empty(filter: _filter)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: wines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final w = wines[i];
                      return WineTile(
                        wine: w,
                        tasting: tasting[w.id],
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
  const _Empty({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _Filter.all => '아직 저장한 와인이 없습니다.',
      _Filter.favorites => '즐겨찾기한 와인이 없습니다.',
      _Filter.tasted => '아직 마신 와인 기록이 없습니다.\n'
          '와인을 열고 "테이스팅 노트"로 평가를 남기면 여기에 모입니다.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wine_bar_outlined,
              size: 56,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
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
