import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../wines/providers/wines_providers.dart';
import '../../wines/widgets/wine_thumb.dart';
import '../models/wine_search_result.dart';
import '../providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: ref.read(searchQueryProvider));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() =>
      ref.read(searchQueryProvider.notifier).state = _ctrl.text.trim();

  Future<void> _add(WineSearchResult r, {required bool favorite}) async {
    final w = await ref
        .read(winesProvider.notifier)
        .addFromSearch(r, favorite: favorite);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(favorite ? '즐겨찾기에 추가했습니다' : '내 와인에 추가했습니다'),
        action: SnackBarAction(
          label: '열기',
          onPressed: () => context.push(Routes.wine(w.id)),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('와인 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '와인 이름 또는 바코드 숫자',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _submit,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? const _Hint()
                : results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('검색 실패: $e', textAlign: TextAlign.center),
                      ),
                    ),
                    data: (res) => ListView(
                      children: [
                        for (final e in res.errors.entries)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber),
                            title: Text('${sourceLabel(e.key)} 조회 실패'),
                            subtitle: Text(e.value),
                          ),
                        if (res.results.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('검색 결과가 없습니다.',
                                textAlign: TextAlign.center),
                          ),
                        for (final r in res.results)
                          _ResultTile(
                            result: r,
                            onAdd: () => _add(r, favorite: false),
                            onFavorite: () => _add(r, favorite: true),
                          ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('찾는 와인이 없나요? 직접 입력하기'),
                          onTap: () => context.push(
                            '${Routes.newWine}?name=${Uri.encodeQueryComponent(query)}',
                          ),
                        ),
                        if (res.results.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Text(
                              '데이터: Open Food Facts (ODbL). 사용자 기여 데이터라 일부 정보가 부정확하거나 비어 있을 수 있습니다.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({
    required this.result,
    required this.onAdd,
    required this.onFavorite,
  });

  final WineSearchResult result;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(winesProvider); // rebuild when saved state changes
    final saved = ref
        .read(winesProvider.notifier)
        .findBySource(result.source, result.sourceId);
    final sub = [
      if (result.producer.isNotEmpty) result.producer,
      if (result.vintage != null) '${result.vintage}',
      result.type.label,
      if (result.originLabel.isNotEmpty) result.originLabel,
    ].join(' · ');
    return ListTile(
      leading: WineThumb(imageUrl: result.imageUrl, type: result.type),
      title: Text(result.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: saved == null ? onAdd : () => context.push(Routes.wine(saved.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: saved == null ? '내 와인에 추가' : '저장됨',
            icon: Icon(
                saved == null ? Icons.add_circle_outline : Icons.check_circle),
            onPressed: saved == null ? onAdd : null,
          ),
          IconButton(
            tooltip: '즐겨찾기',
            icon: Icon(
              saved?.isFavorite == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: saved?.isFavorite == true
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: saved?.isFavorite == true ? null : onFavorite,
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        '와인 이름(영문 권장)이나 병 뒷면 바코드 숫자(EAN/UPC)로 검색합니다.\n\n'
        '검색 데이터는 Open Food Facts 에서 가져옵니다. 등록되지 않은 와인은 '
        '"직접 입력"으로 추가할 수 있습니다.',
      ),
    );
  }
}
