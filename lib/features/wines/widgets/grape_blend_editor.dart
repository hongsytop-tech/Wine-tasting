import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/wine_reference.dart';
import '../models/wine_type.dart';
import 'option_picker.dart';

/// 품종 입력 — 단일 품종 또는 블렌드(여러 품종 + 선택적 비율 %).
class GrapeBlendEditor extends StatefulWidget {
  const GrapeBlendEditor({
    super.key,
    required this.grapes,
    required this.percents,
    required this.wineType,
    required this.onChanged,
  });

  final List<String> grapes;
  final Map<String, int> percents;
  final WineType wineType;
  final void Function(List<String> grapes, Map<String, int> percents) onChanged;

  @override
  State<GrapeBlendEditor> createState() => _GrapeBlendEditorState();
}

class _GrapeBlendEditorState extends State<GrapeBlendEditor> {
  final _pctCtrls = <String, TextEditingController>{};

  TextEditingController _ctrlFor(String grape) => _pctCtrls.putIfAbsent(
        grape,
        () => TextEditingController(
            text: widget.percents[grape]?.toString() ?? ''),
      );

  @override
  void dispose() {
    for (final c in _pctCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 와인 종류에 맞는 색의 품종을 먼저 보여준다 (로제·스파클링 등은 그대로).
  List<RefItem> _options() {
    final taken = widget.grapes.toSet();
    final all = WineReference.grapes.where((g) => !taken.contains(g.label));
    GrapeColor? first;
    if (widget.wineType == WineType.red) first = GrapeColor.red;
    if (widget.wineType == WineType.white) first = GrapeColor.white;
    if (first == null) return all.toList();
    return [
      ...all.where((g) => g.color == first),
      ...all.where((g) => g.color != first),
    ];
  }

  Future<void> _add() async {
    final picked = await showOptionPicker(
      context,
      title: '품종 추가',
      options: _options(),
    );
    if (picked == null || picked.isEmpty) return;
    final g = WineReference.canonicalGrape(picked);
    if (widget.grapes.contains(g)) return;
    widget.onChanged([...widget.grapes, g], widget.percents);
  }

  void _remove(String g) {
    _pctCtrls.remove(g)?.dispose();
    final rest = widget.grapes.where((e) => e != g).toList();
    // 단일 품종이 되면 비율은 의미가 없으므로 지운다.
    widget.onChanged(
      rest,
      rest.length < 2 ? const {} : ({...widget.percents}..remove(g)),
    );
  }

  void _setPercent(String g, String text) {
    final n = int.tryParse(text);
    final next = {...widget.percents};
    if (n == null || n <= 0) {
      next.remove(g);
    } else {
      next[g] = n.clamp(1, 100);
    }
    widget.onChanged(widget.grapes, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grapes = widget.grapes;
    final sum = grapes.fold<int>(0, (a, g) => a + (widget.percents[g] ?? 0));
    final anyPct = grapes.any((g) => widget.percents[g] != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('품종', style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            if (grapes.length > 1)
              const Chip(
                label: Text('블렌드'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 18),
              label: Text(grapes.isEmpty ? '품종 선택' : '품종 추가'),
            ),
          ],
        ),
        if (grapes.isEmpty)
          Text(
            '블렌드 와인은 품종을 여러 개 추가하고, 알면 비율(%)도 넣으세요.',
            style: theme.textTheme.bodySmall,
          ),
        for (final g in grapes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(g)),
                if (grapes.length > 1)
                  SizedBox(
                    width: 76,
                    child: TextField(
                      controller: _ctrlFor(g),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '비율',
                        suffixText: '%',
                      ),
                      onChanged: (t) => _setPercent(g, t),
                    ),
                  ),
                IconButton(
                  tooltip: '삭제',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _remove(g),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        if (grapes.length > 1 && anyPct)
          Text(
            '비율 합계 $sum%${sum == 100 ? '' : ' (100%가 아닙니다)'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: sum == 100 ? null : theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
