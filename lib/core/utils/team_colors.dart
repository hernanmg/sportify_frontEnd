import 'package:flutter/material.dart';

class TeamColorPair {
  final Color primary;
  final Color secondary;

  const TeamColorPair({
    required this.primary,
    required this.secondary,
  });
}

/// Presets comunes para equipos amateur.
const List<({String label, TeamColorPair colors})> teamColorPresets = [
  (label: 'Verde y blanco', colors: TeamColorPair(primary: Color(0xFF1B5E20), secondary: Color(0xFFFFFFFF))),
  (label: 'Azul y dorado', colors: TeamColorPair(primary: Color(0xFF0D47A1), secondary: Color(0xFFFFC107))),
  (label: 'Rojo y negro', colors: TeamColorPair(primary: Color(0xFFC62828), secondary: Color(0xFF212121))),
  (label: 'Celeste y blanco', colors: TeamColorPair(primary: Color(0xFF03A9F4), secondary: Color(0xFFFFFFFF))),
  (label: 'Bordó y blanco', colors: TeamColorPair(primary: Color(0xFF880E4F), secondary: Color(0xFFFFFFFF))),
  (label: 'Negro y amarillo', colors: TeamColorPair(primary: Color(0xFF212121), secondary: Color(0xFFFFEB3B))),
];

String serializeTeamColors(Color primary, Color secondary) {
  return '${_toHex(primary)}|${_toHex(secondary)}';
}

TeamColorPair? parseTeamColors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  if (!raw.contains('|')) return null;
  final parts = raw.split('|');
  if (parts.length != 2) return null;
  final primary = _fromHex(parts[0].trim());
  final secondary = _fromHex(parts[1].trim());
  if (primary == null || secondary == null) return null;
  return TeamColorPair(primary: primary, secondary: secondary);
}

/// Texto libre legacy (ej. "Azul y amarillo") cuando no hay hex.
String? legacyTeamColorsLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  if (raw.contains('|')) return null;
  return raw.trim();
}

String _toHex(Color color) {
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');
  return '#${'$r$g$b'.toUpperCase()}';
}

Color? _fromHex(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length != 6) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
