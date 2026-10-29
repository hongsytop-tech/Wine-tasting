import 'package:flutter/material.dart';

import '../models/taste_attr.dart';
import '../models/tasting_note.dart';
import '../services/tasting_suggest_service.dart';

/// AI 제안 확인 시트. 고른 항목만 [TastingNote] 에 적용한 결과를 돌려준다
/// (취소하면 null). 이미 값이 있는 점수는 기본으로 체크하지 않는다.
Future<TastingNote?> showSuggestionSheet(
  BuildContext context, {
  required TastingNote note,
  required TastingSuggestion suggestion,
}) {
  return showModalBottomSheet<TastingNote>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SuggestionSheet(note: note, s: suggestion),
  );
}

class _SuggestionSheet extends StatefulWidget {
  const _SuggestionSheet({required this.note, required this.s});

  final TastingNote note;
  final TastingSuggestion s;

  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  late final Set<TasteAttr> _scores = {
    for (final a in widget.s.scores.keys)
      if (a.of(widget.note) == null) a,
  };
  late final Set<String> _keywords = {
    for (final k in widget.s.keywords)
      if (!widget.note.keywords.contains(k)) k,
  };
  late bool _color = widget.s.color.isNotEmpty && widget.note.color.isEmpty;

  TastingNote _apply() {
    var n = widget.note;
    for (final a in _scores) {
      n = n.withAttr(a, widget.s.scores[a]!.value);
    }
    if (_keywords.isNotEmpty) {
      n = n.withKeywords(
          [...n.keywords, ..._keywords.where((k) => !n.keywords.contains(k))]);
    }
    if (_color) n = n.copyWith(color: widget.s.color);
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.s;
    final newKeywords = [
      for (final k in s.keywords)
        if (!widget.note.keywords.contains(k)) k
    ];
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text('AI 제안', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '총평을 AI 가 해석한 제안입니다. 맞는 것만 골라 적용하세요. '
                  '"평균 이상" 같은 표현을 숫자로 옮긴 것이라 정확하지 않을 수 있습니다.',
                  style: theme.textTheme.bodySmall,
                ),
                if (s.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('총평에서 옮길 수 있는 항목을 찾지 못했습니다.'),
                  ),
                if (s.scores.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('점수 (0~10)', style: theme.textTheme.labelLarge),
                  for (final e in s.scores.entries)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _scores.contains(e.key),
                      onChanged: (on) => setState(
                        () => on == true
                            ? _scores.add(e.key)
                            : _scores.remove(e.key),
                      ),
                      title: Text(
                        '${e.key.label} ${e.value.value}'
                        '${e.key.of(widget.note) == null ? '' : '  (현재 ${e.key.of(widget.note)})'}',
                      ),
                      subtitle: e.value.evidence.isEmpty
                          ? null
                          : Text('“${e.value.evidence}”'),
                    ),
                ],
                if (s.color.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _color,
                    onChanged: (on) => setState(() => _color = on == true),
                    title: Text(
                      '색상: ${s.color}'
                      '${widget.note.color.isEmpty ? '' : '  (현재 ${widget.note.color})'}',
                    ),
                  ),
                ],
                if (newKeywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('키워드', style: theme.textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final k in newKeywords)
                        FilterChip(
                          label: Text(k),
                          selected: _keywords.contains(k),
                          onSelected: (on) => setState(() =>
                              on ? _keywords.add(k) : _keywords.remove(k)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: s.isEmpty
                          ? null
                          : () => Navigator.pop(context, _apply()),
                      child: const Text('선택한 항목 적용'),
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
