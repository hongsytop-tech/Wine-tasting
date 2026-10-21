import 'package:flutter/material.dart';

import '../models/tasting_vocab.dart';

/// 그룹별 향/맛 묘사어 다중 선택 + 직접 입력.
class DescriptorPicker extends StatefulWidget {
  const DescriptorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<DescriptorPicker> createState() => _DescriptorPickerState();
}

class _DescriptorPickerState extends State<DescriptorPicker> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String d) {
    final next = [...widget.selected];
    next.contains(d) ? next.remove(d) : next.add(d);
    widget.onChanged(next);
  }

  void _addCustom() {
    final d = _custom.text.trim();
    if (d.isEmpty || widget.selected.contains(d)) return;
    widget.onChanged([...widget.selected, d]);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final known = TastingVocab.aromaGroups.values.expand((e) => e).toSet();
    final custom = widget.selected.where((d) => !known.contains(d)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '선택: ${widget.selected.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final g in TastingVocab.aromaGroups.entries)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Builder(
              builder: (_) {
                final n = g.value.where(widget.selected.contains).length;
                return Text(n == 0 ? g.key : '${g.key} ($n)');
              },
            ),
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  for (final d in g.value)
                    FilterChip(
                      label: Text(d),
                      selected: widget.selected.contains(d),
                      onSelected: (_) => _toggle(d),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        Wrap(
          spacing: 6,
          children: [
            for (final d in custom)
              InputChip(label: Text(d), onDeleted: () => _toggle(d)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custom,
                decoration: const InputDecoration(
                  hintText: '직접 입력 (예: 흑연)',
                  isDense: true,
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            IconButton(onPressed: _addCustom, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}
