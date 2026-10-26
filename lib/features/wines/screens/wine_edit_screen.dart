import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../models/wine.dart';
import '../providers/wines_providers.dart';
import '../widgets/wine_info_form.dart';

/// 와인 직접 추가 ([wineId] == null) 또는 정보 수정.
class WineEditScreen extends ConsumerStatefulWidget {
  const WineEditScreen({super.key, this.wineId, this.initialName});

  final String? wineId;
  final String? initialName;

  @override
  ConsumerState<WineEditScreen> createState() => _WineEditScreenState();
}

class _WineEditScreenState extends ConsumerState<WineEditScreen> {
  Wine? _original;
  late WineInfo _info;
  late final TextEditingController _memo;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _original = widget.wineId == null
        ? null
        : ref.read(wineByIdProvider(widget.wineId!));
    final w = _original;
    _info = w == null
        ? WineInfo(name: widget.initialName ?? '')
        : WineInfo.fromWine(w);
    _memo = TextEditingController(text: w?.memo ?? '');
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_info.hasName) {
      setState(() => _nameError = '이름을 입력하세요');
      return;
    }
    if (_info.hasInvalidInput) return;
    final notifier = ref.read(winesProvider.notifier);
    final original = _original;
    if (original == null) {
      final now = DateTime.now();
      final draft =
          _info.applyTo(Wine(id: '', name: '', createdAt: now, updatedAt: now));
      final w =
          await notifier.addManual(draft.copyWith(memo: _memo.text.trim()));
      if (mounted) context.pushReplacement(Routes.wine(w.id));
    } else {
      await notifier
          .update(_info.applyTo(original).copyWith(memo: _memo.text.trim()));
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? '와인 직접 추가' : '와인 정보 수정'),
        actions: [
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WineInfoForm(
            initial: _info,
            knownProducers: ref.watch(knownProducersProvider),
            custom: ref.watch(customRefsProvider),
            nameError: _nameError,
            onChanged: (v) => setState(() {
              _info = v;
              if (v.hasName) _nameError = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
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
    );
  }
}
