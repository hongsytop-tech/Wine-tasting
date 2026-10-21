import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../wines/models/wine_type.dart';
import '../../wines/providers/wines_providers.dart';
import '../../wines/widgets/rating_stars.dart';
import '../models/taste_attr.dart';
import '../models/tasting_note.dart';
import '../models/tasting_vocab.dart';
import '../providers/tasting_providers.dart';
import '../widgets/descriptor_picker.dart';
import '../widgets/score_slider.dart';

/// 테이스팅 노트 작성 ([wineId]) 또는 수정 ([noteId]).
class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({super.key, this.wineId, this.noteId})
      : assert(wineId != null || noteId != null);

  final String? wineId;
  final String? noteId;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  TastingNote? _note;
  bool _isNew = false;
  late final TextEditingController _place;
  late final TextEditingController _companions;
  late final TextEditingController _pairing;
  late final TextEditingController _price;
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(tastingNotesProvider.notifier);
    if (widget.noteId != null) {
      for (final n in ref.read(visibleNotesProvider)) {
        if (n.id == widget.noteId) _note = n;
      }
    } else {
      _note = notifier.newDraft(widget.wineId!);
      _isNew = true;
    }
    final n = _note;
    _place = TextEditingController(text: n?.place ?? '');
    _companions = TextEditingController(text: n?.companions ?? '');
    _pairing = TextEditingController(text: n?.pairing ?? '');
    _price = TextEditingController(text: n?.price?.toString() ?? '');
    _comment = TextEditingController(text: n?.comment ?? '');
  }

  @override
  void dispose() {
    for (final c in [_place, _companions, _pairing, _price, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(TastingNote Function(TastingNote n) f) =>
      setState(() => _note = f(_note!));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _note!.tastedAt,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) _set((n) => n.copyWith(tastedAt: d));
  }

  Future<void> _save() async {
    final n = _note!.copyWith(
      place: _place.text.trim(),
      companions: _companions.text.trim(),
      pairing: _pairing.text.trim(),
      price: int.tryParse(_price.text.trim()),
      comment: _comment.text.trim(),
    );
    await ref.read(tastingNotesProvider.notifier).save(n);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('이 테이스팅 노트를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tastingNotesProvider.notifier).delete(_note!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final n = _note;
    if (n == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('노트를 찾을 수 없습니다.')),
      );
    }
    final wine = ref.watch(wineByIdProvider(n.wineId));
    final type = wine?.type ?? WineType.other;
    final theme = Theme.of(context);

    Widget score(TasteAttr a) => ScoreSlider(
          attr: a,
          value: a.of(n),
          onChanged: (v) => _set((x) => x.withAttr(a, v)),
        );

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(title, style: theme.textTheme.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '테이스팅 노트' : '노트 수정'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: '삭제',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (wine != null)
            Text(
              '${wine.name} (${wine.vintageLabel})',
              style: theme.textTheme.titleSmall,
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title:
                Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(n.tastedAt)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickDate,
          ),
          TextField(
            controller: _place,
            decoration: const InputDecoration(labelText: '장소', isDense: true),
          ),
          TextField(
            controller: _companions,
            decoration:
                const InputDecoration(labelText: '함께한 사람', isDense: true),
          ),
          section('평점'),
          Row(
            children: [
              RatingStars(
                value: n.rating,
                size: 36,
                onChanged: (v) => _set((x) => x.copyWith(rating: v)),
              ),
              const SizedBox(width: 8),
              Text(ratingText(n.rating), style: theme.textTheme.titleMedium),
            ],
          ),
          section('외관'),
          Wrap(
            spacing: 6,
            children: [
              for (final c in TastingVocab.colorsFor(type))
                ChoiceChip(
                  label: Text(c),
                  selected: n.color == c,
                  onSelected: (_) =>
                      _set((x) => x.copyWith(color: x.color == c ? '' : c)),
                ),
            ],
          ),
          score(TasteAttr.colorIntensity),
          section('향 (Nose)'),
          score(TasteAttr.aromaIntensity),
          DescriptorPicker(
            selected: n.aromas,
            onChanged: (v) => _set((x) => x.copyWith(aromas: v)),
          ),
          section('맛 (Palate) · 0~10점'),
          for (final a in TasteAttr.palate)
            if (a.appliesTo(type) || a.of(n) != null) score(a),
          const SizedBox(height: 8),
          Text('맛에서 느낀 풍미', style: theme.textTheme.labelLarge),
          DescriptorPicker(
            selected: n.flavors,
            onChanged: (v) => _set((x) => x.copyWith(flavors: v)),
          ),
          section('결론'),
          TextField(
            controller: _pairing,
            decoration:
                const InputDecoration(labelText: '페어링한 음식', isDense: true),
          ),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '구매가',
              suffixText: '원',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '총평',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
