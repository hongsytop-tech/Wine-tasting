import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../wines/models/wine.dart';
import '../../wines/models/wine_reference.dart';
import '../../wines/providers/wines_providers.dart';
import '../../wines/widgets/rating_stars.dart';
import '../../wines/widgets/wine_info_form.dart';
import '../../wines/widgets/wine_avatar.dart';
import '../models/taste_attr.dart';
import '../models/tasting_note.dart';
import '../models/tasting_vocab.dart';
import '../providers/photo_providers.dart';
import '../services/label_photo_service.dart';
import '../providers/tasting_providers.dart';
import '../widgets/descriptor_picker.dart';
import '../widgets/photo_strip_editor.dart';
import '../widgets/score_slider.dart';

/// 테이스팅 노트 작성·수정.
/// - [noteId]: 기존 노트 수정
/// - [wineId]: 그 와인의 새 노트
/// - 둘 다 null: 새 노트 — 내 와인에서 고르거나 새 와인 정보를 입력
///
/// 상단 "와인 정보"(생산자·빈티지·국가·지역·품종)를 노트 화면에서 바로
/// 고르거나 고칠 수 있고, 저장하면 와인에 반영된다.
class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({super.key, this.wineId, this.noteId});

  final String? wineId;
  final String? noteId;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  TastingNote? _note;
  bool _isNew = false;

  /// 노트가 연결된 와인. null = 새 와인 입력 중.
  Wine? _wine;
  WineInfo _info = const WineInfo();
  String? _nameError;

  /// 이번 편집에서 새로 올린 사진 (저장 안 하고 나가면 삭제).
  final _uploaded = <String>{};
  List<String> _originalPhotos = const [];
  bool _uploading = false;
  bool _saved = false;

  /// dispose 에서는 ref 를 쓸 수 없으므로 미리 잡아 둔다.
  late final LabelPhotoService _photos;

  late final TextEditingController _place;
  late final TextEditingController _companions;
  late final TextEditingController _pairing;
  late final TextEditingController _price;
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(labelPhotoServiceProvider);
    final notifier = ref.read(tastingNotesProvider.notifier);
    if (widget.noteId != null) {
      for (final n in ref.read(visibleNotesProvider)) {
        if (n.id == widget.noteId) _note = n;
      }
      _originalPhotos = _note?.photos ?? const [];
    } else {
      _note = notifier.newDraft(widget.wineId ?? '');
      _isNew = true;
    }
    final n = _note;
    if (n != null && n.wineId.isNotEmpty) {
      _wine = ref.read(wineByIdProvider(n.wineId));
    }
    if (_wine != null) _info = WineInfo.fromWine(_wine!);
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
    // 저장하지 않고 나가면 이번에 올린 사진 파일은 지운다.
    if (!_saved && _uploaded.isNotEmpty) {
      _photos.remove(_uploaded);
    }
    super.dispose();
  }

  void _set(TastingNote Function(TastingNote n) f) =>
      setState(() => _note = f(_note!));

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _note!.tastedAt,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) _set((n) => n.copyWith(tastedAt: d));
  }

  Future<void> _chooseExistingWine() async {
    final picked = await showModalBottomSheet<Wine>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _WinePickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      _wine = picked;
      _info = WineInfo.fromWine(picked);
      _nameError = null;
    });
  }

  void _clearWine() => setState(() {
        _wine = null;
        _info = const WineInfo();
      });

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploading = true);
    try {
      final path =
          await _photos.pickAndUpload(noteId: _note!.id, source: source);
      if (path != null) {
        _uploaded.add(path);
        _set((n) => n.copyWith(photos: [...n.photos, path]));
      }
    } catch (e) {
      _snack('사진 업로드 실패: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(String path) => _set(
      (n) => n.copyWith(photos: n.photos.where((p) => p != path).toList()));

  Future<void> _save() async {
    if (!_info.hasName) {
      setState(() => _nameError = '와인 이름을 입력하거나 내 와인에서 고르세요');
      _snack('와인 이름이 필요합니다');
      return;
    }
    if (_info.vintageInvalid) {
      _snack('빈티지 연도를 확인하세요');
      return;
    }
    final wines = ref.read(winesProvider.notifier);
    var wine = _wine;
    if (wine == null) {
      final now = DateTime.now();
      wine = await wines.addManual(
        _info.applyTo(Wine(id: '', name: '', createdAt: now, updatedAt: now)),
      );
    } else if (_info.differsFrom(wine)) {
      await wines.update(_info.applyTo(wine));
    }

    final n = _note!.copyWith(
      wineId: wine.id,
      place: _place.text.trim(),
      companions: _companions.text.trim(),
      pairing: _pairing.text.trim(),
      price: int.tryParse(_price.text.trim()),
      comment: _comment.text.trim(),
    );
    await ref.read(tastingNotesProvider.notifier).save(n);
    _saved = true;
    // 편집 중 뺀 사진(원래 있던 것 + 이번에 올렸다 뺀 것) 파일 삭제.
    final removed =
        {..._originalPhotos, ..._uploaded}.difference(n.photos.toSet());
    await _photos.remove(removed);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('이 테이스팅 노트와 라벨 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // 저장된 노트의 사진은 notifier.delete 가 지우고, 이번 편집에서 새로 올린
    // (아직 저장 안 된) 사진은 여기서 지운다.
    await _photos.remove(_uploaded);
    await ref.read(tastingNotesProvider.notifier).delete(_note!.id);
    _saved = true;
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
    final type = _info.type;
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
          TextButton(
            onPressed: _uploading ? null : _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _wineSection(theme),
          section('라벨 사진'),
          PhotoStripEditor(
            photos: n.photos,
            enabled: SupabaseService.isSignedIn,
            uploading: _uploading,
            onAdd: _addPhoto,
            onRemove: _removePhoto,
          ),
          section('시음 정보'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
              DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(n.tastedAt),
            ),
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

  /// 와인 정보 섹션 — 새 노트면 내 와인 선택 / 새 와인 입력, 기존 와인이면 수정.
  Widget _wineSection(ThemeData theme) {
    final w = _wine;
    final canChangeWine = _isNew && widget.wineId == null;
    final missing = _info.country.isEmpty || _info.grapes.isEmpty;
    final summary = [
      if (_info.producer.isNotEmpty) _info.producer,
      _info.vintage?.toString() ?? 'NV',
      if (_info.country.isNotEmpty) _info.country,
      if (_info.grapes.isNotEmpty)
        _info.grapes.length > 1
            ? '블렌드 ${_info.grapes.length}종'
            : _info.grapes.first,
    ].join(' · ');

    final form = WineInfoForm(
      // 다른 와인을 고르면 폼을 새 값으로 다시 만든다.
      key: ValueKey(w?.id ?? 'new'),
      initial: _info,
      knownProducers: ref.watch(knownProducersProvider),
      nameError: _nameError,
      onChanged: (v) => setState(() {
        _info = v;
        if (v.hasName) _nameError = null;
      }),
    );

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canChangeWine)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _chooseExistingWine,
                      icon: const Icon(Icons.wine_bar, size: 18),
                      label: const Text('내 와인에서 선택'),
                    ),
                    if (w != null)
                      OutlinedButton.icon(
                        onPressed: _clearWine,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('새 와인 입력'),
                      ),
                  ],
                ),
              ),
            if (w == null)
              // 새 와인: 폼을 펼쳐서 보여준다.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('새 와인 정보', style: theme.textTheme.titleMedium),
                  ),
                  form,
                ],
              )
            else
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                // 국가·품종이 비어 있으면 채우도록 펼쳐 둔다.
                initiallyExpanded: missing,
                leading: WineAvatar(wine: w, size: 40),
                title: Text(
                  _info.name.isEmpty ? '(이름 없음)' : _info.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle:
                    Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [
                  const SizedBox(height: 8),
                  form,
                  const SizedBox(height: 4),
                  Text(
                    '여기서 고친 와인 정보는 저장할 때 내 와인에도 반영됩니다.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 내 와인 목록에서 하나 고르기 (검색 가능).
class _WinePickerSheet extends ConsumerStatefulWidget {
  const _WinePickerSheet();

  @override
  ConsumerState<_WinePickerSheet> createState() => _WinePickerSheetState();
}

class _WinePickerSheetState extends ConsumerState<_WinePickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = foldText(_q);
    final wines = ref
        .watch(visibleWinesProvider)
        .where(
          (w) =>
              q.isEmpty ||
              foldText(w.name).contains(q) ||
              foldText(w.producer).contains(q),
        )
        .toList();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (t) => setState(() => _q = t),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '와인 이름 또는 생산자',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: wines.isEmpty
                  ? const Center(child: Text('내 와인이 없습니다.'))
                  : ListView(
                      children: [
                        for (final w in wines)
                          ListTile(
                            leading: WineAvatar(wine: w, size: 40),
                            title: Text(w.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                if (w.producer.isNotEmpty) w.producer,
                                w.vintageLabel,
                                if (w.country.isNotEmpty) w.country,
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.pop(context, w),
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
