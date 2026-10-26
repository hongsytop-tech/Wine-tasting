/// Lenient JSON readers shared by models. Local cache uses camelCase keys,
/// Supabase rows use snake_case — readers accept either.
class J {
  J._();

  static String str(Map<String, dynamic> j, String camel, [String? snake]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    return v == null ? '' : '$v';
  }

  static String? strOrNull(
    Map<String, dynamic> j,
    String camel, [
    String? snake,
  ]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v == null) return null;
    final s = '$v';
    return s.isEmpty ? null : s;
  }

  static int? intOrNull(Map<String, dynamic> j, String camel, [String? snake]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static double? doubleOrNull(
    Map<String, dynamic> j,
    String camel, [
    String? snake,
  ]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  static bool boolean(Map<String, dynamic> j, String camel, [String? snake]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    return v == true || v == 'true';
  }

  static List<String> strList(
    Map<String, dynamic> j,
    String camel, [
    String? snake,
  ]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v is List) return v.map((e) => '$e').toList();
    return const [];
  }

  /// {"이름": 정수} 맵 (값이 숫자가 아니면 건너뜀).
  static Map<String, int> intMap(
    Map<String, dynamic> j,
    String camel, [
    String? snake,
  ]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v is! Map) return const {};
    final out = <String, int>{};
    for (final e in v.entries) {
      final n = e.value is num
          ? (e.value as num).toInt()
          : int.tryParse('${e.value}');
      if (n != null) out['${e.key}'] = n;
    }
    return out;
  }

  static DateTime? date(Map<String, dynamic> j, String camel, [String? snake]) {
    final v = j[camel] ?? (snake == null ? null : j[snake]);
    if (v == null) return null;
    return DateTime.tryParse('$v')?.toLocal();
  }

  static String? iso(DateTime? d) => d?.toUtc().toIso8601String();
}
