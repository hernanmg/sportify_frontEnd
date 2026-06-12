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

  const HelpArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.steps,
    this.tip,
  });

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      title,
      summary,
      ...keywords,
      ...steps,
      if (tip != null) tip!,
    ].join(' ').toLowerCase();
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
    if (tokens.isEmpty) return haystack.contains(q);
    return tokens.every(haystack.contains);
  }
}
