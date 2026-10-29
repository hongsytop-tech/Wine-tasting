import 'package:flutter/material.dart';

import '../../wines/models/wine_reference.dart';
import '../models/tasting_vocab.dart';
import 'descriptor_picker.dart';

/// 향·맛 키워드 입력 — 글자를 치면 후보가 뜨고(Enter 로 그대로 추가),
/// 자주 쓴 키워드는 칩으로 바로 고른다. 전체 목록은 시트에서 그룹별로 본다.
class KeywordInput extends StatefulWidget {
  const KeywordInput({
    super.key,
    required this.selected,
    required this.onChanged,
    this.frequent = const [],
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// 내가 자주 쓴 키워드 (많이 쓴 순).
  final List<String> frequent;

  /// 처음 써서 자주 쓴 키워드가 없을 때 보여줄 기본 후보.
  static const _starters = ['체리', '블랙베리', '자두', '바닐라', '오크', '후추', '레몬', '청사과'];

  static List<String> get vocabulary => TastingVocab.allDescriptors;

  @override
  State<KeywordInput> createState() => _KeywordInputState();
}

class _KeywordInputState extends State<KeywordInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String k) {
    final t = k.trim();
    _ctrl.clear();
    if (t.isEmpty || widget.selected.contains(t)) return;
    widget.onChanged([...widget.selected, t]);
  }

  void _remove(String k) =>
      widget.onChanged(widget.selected.where((e) => e != k).toList());

  Future<void> _browse() async {
    var picked = [...widget.selected];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('향·맛 키워드 목록', style: Theme.of(ctx).textTheme.titleMedium),
              DescriptorPicker(
                selected: picked,
                onChanged: (v) {
                  setSheet(() => picked = v);
                  widget.onChanged(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quick = [
      ...(widget.frequent.isEmpty ? KeywordInput._starters : widget.frequent),
    ].where((k) => !widget.selected.contains(k)).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final k in widget.selected)
                InputChip(label: Text(k), onDeleted: () => _remove(k)),
            ],
          ),
        RawAutocomplete<String>(
          textEditingController: _ctrl,
          focusNode: _focus,
          optionsBuilder: (v) {
            final q = foldText(v.text);
            if (q.isEmpty) return const [];
            final pool = {...widget.frequent, ...KeywordInput.vocabulary};
            return pool
                .where((k) =>
                    !widget.selected.contains(k) && foldText(k).contains(q))
                .take(8);
          },
          onSelected: _add,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: '키워드 입력 (예: 후추, 체리)',
              isDense: true,
              suffixIcon: IconButton(
                tooltip: '추가',
                icon: const Icon(Icons.add),
                onPressed: () => _add(controller.text),
              ),
            ),
            onSubmitted: (t) {
              _add(t);
              focusNode.requestFocus();
            },
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 240, maxWidth: 320),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                          dense: true,
                          title: Text(o),
                          onTap: () => onSelected(o)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    widget.frequent.isEmpty ? '추천' : '자주 쓴',
                    style: theme.textTheme.bodySmall,
                  ),
                  for (final k in quick)
                    ActionChip(
                      label: Text(k),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _add(k),
                    ),
                ],
              ),
            ),
          ],
        ),
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: _browse,
          icon: const Icon(Icons.list, size: 18),
          label: const Text('전체 목록에서 고르기'),
        ),
      ],
    );
  }
}
