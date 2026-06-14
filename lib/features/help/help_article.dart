import 'package:flutter/material.dart';

class HelpArticle {
  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final List<String> steps;
  final String? tip;
  /// Identificador de vista previa embebida (`lineup`, etc.).
  final String? previewType;

  const HelpArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.steps,
    this.tip,
    this.previewType,
  });

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  bool matchesQuery(String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;

    final titleN = normalize(title);
    if (titleN.contains(q) || q.contains(titleN)) return true;

    if (normalize(id).contains(q.replaceAll(' ', ''))) return true;

    for (final k in keywords) {
      final kn = normalize(k);
      if (kn.contains(q) || q.contains(kn)) return true;
    }

    final summaryN = normalize(summary);
    if (summaryN.contains(q)) return true;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2);
    if (tokens.isEmpty) {
      return steps.any((s) => normalize(s).contains(q));
    }

    return tokens.every(
      (t) =>
          summaryN.contains(t) ||
          steps.any((s) => normalize(s).contains(t)),
    );
  }
}
