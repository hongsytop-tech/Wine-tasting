import 'package:flutter/material.dart';

import '../models/wine_reference.dart';

/// 검색 가능한 선택 시트. 목록에 없으면 입력한 글자 그대로 "직접 입력" 할 수 있다.
/// 반환: 선택한 라벨 / 직접 입력값 / '' (지우기) / null (취소).
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<RefItem> options,
  String current = '',
  String? emptyHint,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _OptionPickerSheet(
      title: title,
      options: options,
      current: current,
      emptyHint: emptyHint,
    ),
  );
}

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.current,
    this.emptyHint,
  });

  final String title;
  final List<RefItem> options;
  final String current;
  final String? emptyHint;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim();
    final matches = widget.options.where((o) => o.matches(q)).toList();
    final exact = q.isNotEmpty && widget.options.any((o) => o.isExactly(q));
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text(widget.title, style: theme.textTheme.titleMedium),
                  ),
                  if (widget.current.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('지우기'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (q.isEmpty) return;
                  Navigator.pop(
                    context,
                    matches.length == 1 ? matches.first.label : q,
                  );
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '검색 (한글·영문)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                children: [
                  if (q.isNotEmpty && !exact)
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('직접 입력: "$q"'),
                      onTap: () => Navigator.pop(context, q),
                    ),
                  if (widget.options.isEmpty && q.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.emptyHint ?? '목록이 없습니다. 위에 입력하세요.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  for (final o in matches)
                    ListTile(
                      dense: true,
                      title: Text(o.label),
                      subtitle:
                          o.aliases.isEmpty ? null : Text(o.aliases.join(', ')),
                      trailing: o.label == widget.current
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(context, o.label),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 값을 보여주고 누르면 [showOptionPicker] 를 여는 입력칸.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value.isEmpty || onClear == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  tooltip: '지우기',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
