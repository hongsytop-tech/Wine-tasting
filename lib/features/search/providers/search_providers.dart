import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wine_search_service.dart';

final wineSearchServiceProvider = Provider((_) => WineSearchService());

/// 현재 검색어. 빈 문자열이면 검색하지 않는다.
final searchQueryProvider = StateProvider<String>((_) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<WineSearchResponse>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return const WineSearchResponse(results: []);
  return ref.read(wineSearchServiceProvider).search(q);
});
