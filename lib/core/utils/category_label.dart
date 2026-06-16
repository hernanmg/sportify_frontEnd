/// Etiquetas cortas de categoría (M+35, M-Libre, F+30) en toda la app.
class CategoryLabels {
  CategoryLabels._();

  static const _map = <String, String>{
    'Libre': 'M-Libre',
    'Masculino Libre': 'M-Libre',
    'Masculino': '',
    '+35': 'M+35',
    'Masculino +35': 'M+35',
    '+40': 'M+40',
    'Masculino +40': 'M+40',
    '+45': 'M+45',
    'Masculino +45': 'M+45',
    'Femenino': '',
    'Femenino +30': 'F+30',
    'Juvenil': 'Juvenil',
  };

  static String short(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final n = name.trim();
    final mapped = _map[n];
    if (mapped != null) return mapped;
    if (RegExp(r'^[MF][+\-]').hasMatch(n) || n == 'Juvenil') return n;
    return n
        .replaceFirst(RegExp(r'^Masculino\s*', caseSensitive: false), 'M')
        .replaceFirst(RegExp(r'^Femenino\s*', caseSensitive: false), 'F')
        .replaceAll(' ', '');
  }

  /// Comparación flexible: M+40, +40, Masculino +40, etc.
  static bool matches(String? a, String? b) {
    if (a == null || b == null) return false;
    final sa = short(a);
    final sb = short(b);
    if (sa.isNotEmpty && sb.isNotEmpty) return sa == sb;
    final na = RegExp(r'(\d+)').firstMatch(a)?.group(1);
    final nb = RegExp(r'(\d+)').firstMatch(b)?.group(1);
    if (na != null && nb != null) return na == nb;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static bool isGenericGenderOnly(String? name) {
    final n = name?.trim().toLowerCase() ?? '';
    return n == 'masculino' || n == 'femenino';
  }
}
