import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/wine.dart';
import '../models/wine_reference.dart';
import '../models/wine_type.dart';
import 'grape_blend_editor.dart';
import 'option_picker.dart';

/// 와인 기본 정보 (이름·생산자·빈티지·종류·국가·지역·품종) 입력값.
class WineInfo {
  const WineInfo({
    this.name = '',
    this.producer = '',
    this.vintage,
    this.type = WineType.red,
    this.country = '',
    this.region = '',
    this.grapes = const [],
    this.grapePercents = const {},
    this.vintageInvalid = false,
  });

  factory WineInfo.fromWine(Wine w) => WineInfo(
        name: w.name,
        producer: w.producer,
        vintage: w.vintage,
        type: w.type,
        country: w.country,
        region: w.region,
        grapes: w.grapes,
        grapePercents: w.grapePercents,
      );

  final String name;
  final String producer;
  final int? vintage;
  final WineType type;
  final String country;
  final String region;
  final List<String> grapes;
  final Map<String, int> grapePercents;

  /// 빈티지 칸에 잘못된 연도가 입력돼 있음 (저장 막기용, 저장되지 않는 값).
  final bool vintageInvalid;

  bool get hasName => name.trim().isNotEmpty;

  /// [w] 에 이 입력값을 덮어쓴 사본 (나머지 필드는 유지).
  Wine applyTo(Wine w) => w.copyWith(
        name: name.trim(),
        producer: producer.trim(),
        vintage: vintage,
        type: type,
        country: country.trim(),
        region: region.trim(),
        grapes: grapes,
        grapePercents: grapePercents,
      );

  /// [w] 와 비교해 바뀐 것이 있는지.
  bool differsFrom(Wine w) {
    final a = applyTo(w);
    return a.name != w.name ||
        a.producer != w.producer ||
        a.vintage != w.vintage ||
        a.type != w.type ||
        a.country != w.country ||
        a.region != w.region ||
        a.grapes.join('\u0000') != w.grapes.join('\u0000') ||
        !_sameMap(a.grapePercents, w.grapePercents);
  }

  static bool _sameMap(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  WineInfo copyWith({
    String? name,
    String? producer,
    Object? vintage = _keep,
    WineType? type,
    String? country,
    String? region,
    List<String>? grapes,
    Map<String, int>? grapePercents,
    bool? vintageInvalid,
  }) =>
      WineInfo(
        name: name ?? this.name,
        producer: producer ?? this.producer,
        vintage: identical(vintage, _keep) ? this.vintage : vintage as int?,
        type: type ?? this.type,
        country: country ?? this.country,
        region: region ?? this.region,
        grapes: grapes ?? this.grapes,
        grapePercents: grapePercents ?? this.grapePercents,
        vintageInvalid: vintageInvalid ?? this.vintageInvalid,
      );

  static const _keep = Object();

  /// 빈티지 입력 검사. null = 정상 (빈칸 = NV).
  static String? vintageError(String text) {
    final s = text.trim();
    if (s.isEmpty) return null;
    final y = int.tryParse(s);
    final max = DateTime.now().year;
    if (y == null || y < 1800 || y > max) return '1800 ~ $max 사이 연도';
    return null;
  }
}

/// 와인 정보 입력 폼. 국가·지역·품종은 목록에서 고르거나 직접 입력,
/// 생산자는 내 와인에 이미 있는 생산자를 자동완성으로 제안한다.
class WineInfoForm extends StatefulWidget {
  const WineInfoForm({
    super.key,
    required this.initial,
    required this.onChanged,
    this.knownProducers = const [],
    this.nameError,
  });

  final WineInfo initial;
  final ValueChanged<WineInfo> onChanged;
  final List<String> knownProducers;

  /// 저장 시도 후 이름이 비어 있으면 부모가 넘겨주는 오류 문구.
  final String? nameError;

  @override
  State<WineInfoForm> createState() => _WineInfoFormState();
}

class _WineInfoFormState extends State<WineInfoForm> {
  late WineInfo _v = widget.initial;
  late final _name = TextEditingController(text: _v.name);
  late final _producer = TextEditingController(text: _v.producer);
  late final _vintage =
      TextEditingController(text: _v.vintage?.toString() ?? '');
  final _producerFocus = FocusNode();
  String? _vintageError;

  @override
  void dispose() {
    _name.dispose();
    _producer.dispose();
    _vintage.dispose();
    _producerFocus.dispose();
    super.dispose();
  }

  void _emit(WineInfo next) {
    setState(() => _v = next);
    widget.onChanged(next);
  }

  Future<void> _pickCountry() async {
    final r = await showOptionPicker(
      context,
      title: '국가',
      options: WineReference.countries,
      current: _v.country,
    );
    if (r == null) return;
    final c = WineReference.canonicalCountry(r);
    // 국가가 바뀌면 그 나라 산지가 아닌 지역은 비운다.
    final keepRegion = _v.region.isEmpty ||
        WineReference.countryOfRegion(_v.region) == null ||
        WineReference.countryOfRegion(_v.region) == c;
    _emit(_v.copyWith(country: c, region: keepRegion ? _v.region : ''));
  }

  Future<void> _pickRegion() async {
    final options = _v.country.isEmpty
        ? WineReference.allRegions
        : WineReference.regionsFor(_v.country);
    final r = await showOptionPicker(
      context,
      title: _v.country.isEmpty ? '지역' : '지역 (${_v.country})',
      options: options,
      current: _v.region,
      emptyHint: '이 국가는 산지 목록이 없습니다. 위에 직접 입력하세요.',
    );
    if (r == null) return;
    final region = WineReference.canonicalRegion(r);
    // 목록의 산지를 고르면 국가가 비어 있을 때 자동으로 채운다.
    final country = _v.country.isEmpty
        ? (WineReference.countryOfRegion(region) ?? '')
        : _v.country;
    _emit(_v.copyWith(region: region, country: country));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: '와인 이름 *',
            border: const OutlineInputBorder(),
            errorText: widget.nameError,
          ),
          onChanged: (t) => _emit(_v.copyWith(name: t)),
        ),
        gap,
        RawAutocomplete<String>(
          textEditingController: _producer,
          focusNode: _producerFocus,
          optionsBuilder: (value) {
            final q = foldText(value.text);
            if (q.isEmpty) return const [];
            return widget.knownProducers
                .where((p) => foldText(p).contains(q) && p != value.text)
                .take(8);
          },
          onSelected: (p) => _emit(_v.copyWith(producer: p)),
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: '생산자 (와이너리)',
              border: OutlineInputBorder(),
            ),
            onChanged: (t) => _emit(_v.copyWith(producer: t)),
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 240, maxWidth: 360),
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
        gap,
        TextField(
          controller: _vintage,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: '빈티지 (비우면 NV)',
            border: const OutlineInputBorder(),
            errorText: _vintageError,
          ),
          onChanged: (t) {
            _vintageError = WineInfo.vintageError(t);
            _emit(_v.copyWith(
              vintage:
                  _vintageError == null ? int.tryParse(t.trim()) : _v.vintage,
              vintageInvalid: _vintageError != null,
            ));
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
                selected: _v.type == t,
                onSelected: (_) => _emit(_v.copyWith(type: t)),
              ),
          ],
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: PickerField(
                label: '국가',
                value: _v.country,
                onTap: _pickCountry,
                onClear: () => _emit(_v.copyWith(country: '')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PickerField(
                label: '지역',
                value: _v.region,
                onTap: _pickRegion,
                onClear: () => _emit(_v.copyWith(region: '')),
              ),
            ),
          ],
        ),
        gap,
        GrapeBlendEditor(
          grapes: _v.grapes,
          percents: _v.grapePercents,
          wineType: _v.type,
          onChanged: (g, p) => _emit(_v.copyWith(grapes: g, grapePercents: p)),
        ),
      ],
    );
  }
}
