import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../models/wine.dart';
import '../models/wine_type.dart';
import '../providers/wines_providers.dart';

/// 와인 직접 추가 ([wineId] == null) 또는 정보 수정.
class WineEditScreen extends ConsumerStatefulWidget {
  const WineEditScreen({super.key, this.wineId, this.initialName});

  final String? wineId;
  final String? initialName;

  @override
  ConsumerState<WineEditScreen> createState() => _WineEditScreenState();
}

class _WineEditScreenState extends ConsumerState<WineEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _producer;
  late final TextEditingController _vintage;
  late final TextEditingController _country;
  late final TextEditingController _region;
  late final TextEditingController _grapes;
  late final TextEditingController _memo;
  WineType _type = WineType.red;
  Wine? _original;

  @override
  void initState() {
    super.initState();
    _original = widget.wineId == null
        ? null
        : ref.read(wineByIdProvider(widget.wineId!));
    final w = _original;
    _name = TextEditingController(text: w?.name ?? widget.initialName ?? '');
    _producer = TextEditingController(text: w?.producer ?? '');
    _vintage = TextEditingController(text: w?.vintage?.toString() ?? '');
    _country = TextEditingController(text: w?.country ?? '');
    _region = TextEditingController(text: w?.region ?? '');
    _grapes = TextEditingController(text: w?.grapes.join(', ') ?? '');
    _memo = TextEditingController(text: w?.memo ?? '');
    _type = w?.type ?? WineType.red;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _producer,
      _vintage,
      _country,
      _region,
      _grapes,
      _memo
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final grapes = _grapes.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final vintage = int.tryParse(_vintage.text.trim());
    final notifier = ref.read(winesProvider.notifier);
    final original = _original;
    if (original == null) {
      final now = DateTime.now();
      final w = await notifier.addManual(Wine(
        id: '',
        name: _name.text.trim(),
        producer: _producer.text.trim(),
        vintage: vintage,
        type: _type,
        country: _country.text.trim(),
        region: _region.text.trim(),
        grapes: grapes,
        memo: _memo.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));
      if (mounted) context.pushReplacement(Routes.wine(w.id));
    } else {
      await notifier.update(original.copyWith(
        name: _name.text.trim(),
        producer: _producer.text.trim(),
        vintage: vintage,
        type: _type,
        country: _country.text.trim(),
        region: _region.text.trim(),
        grapes: grapes,
        memo: _memo.text.trim(),
      ));
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? '와인 직접 추가' : '와인 정보 수정'),
        actions: [
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '와인 이름 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
            ),
            gap,
            TextFormField(
              controller: _producer,
              decoration: const InputDecoration(
                labelText: '생산자 (와이너리)',
                border: OutlineInputBorder(),
              ),
            ),
            gap,
            TextFormField(
              controller: _vintage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '빈티지 (비우면 NV)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                final y = int.tryParse(s);
                final max = DateTime.now().year;
                if (y == null || y < 1800 || y > max) {
                  return '1800 ~ $max 사이 연도를 입력하세요';
                }
                return null;
              },
            ),
            gap,
            Text('종류', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in WineType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _country,
                    decoration: const InputDecoration(
                      labelText: '국가',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _region,
                    decoration: const InputDecoration(
                      labelText: '지역',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            gap,
            TextFormField(
              controller: _grapes,
              decoration: const InputDecoration(
                labelText: '품종 (쉼표로 구분)',
                hintText: '카베르네 소비뇽, 메를로',
                border: OutlineInputBorder(),
              ),
            ),
            gap,
            TextFormField(
              controller: _memo,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '메모 (구매처, 보관 위치 등)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
