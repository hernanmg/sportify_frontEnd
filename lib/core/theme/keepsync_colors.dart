import 'package:flutter/material.dart';

/// Tokens de marca KeepSync Sports (alineados a landing /keepsync).
abstract final class KeepSyncColors {
  // Core
  static const ink = Color(0xFF0A1628);
  static const ink2 = Color(0xFF12233D);
  static const ink3 = Color(0xFF1B3152);
  static const volt = Color(0xFFC8F031);
  static const volt2 = Color(0xFFB4DC1E);
  static const pitchBlue = Color(0xFF3D6BFF);
  static const turf = Color(0xFF12B76A);
  static const flare = Color(0xFFF04438);
  static const paper = Color(0xFFF4F6FA);
  static const white = Color(0xFFFFFFFF);

  // Borders
  static const borderLight = Color(0xFFDDE3EE);
  static const borderDark = Color(0xFF24395C);

  // Muted text
  static const mutedLight = Color(0xFF4A5A72);
  static const mutedDark = Color(0xFFA9B6CC);

  // Hero / code window (landing)
  static const codeBg = Color(0xFF0D1B31);
  static const codeKeyword = Color(0xFF8FB0FF);
  static const codeString = Color(0xFFFFC58A);
  static const codeComment = Color(0xFF6F84A6);

  // Finance (producto)
  static const financePositiveLight = Color(0xFF067647);
  static const financePositiveDark = Color(0xFF47E08F);
  static const financeNegativeLight = Color(0xFFC4231A);
  static const financeNegativeDark = Color(0xFFFF8A80);

  /// Texto sobre Volt (siempre Ink).
  static const onVolt = ink;

  /// Volt “badge” con texto oscuro oliva.
  static const onVoltMuted = Color(0xFF3A4A12);
}

/// Extension de tema para semántica KeepSync (éxito, finanzas, etc.).
@immutable
class KeepSyncThemeExt extends ThemeExtension<KeepSyncThemeExt> {
  final Color success;
  final Color onSuccess;
  final Color financePositive;
  final Color financeNegative;
  final Color accentLink;
  final Color surfaceElevated;
  final Color border;

  const KeepSyncThemeExt({
    required this.success,
    required this.onSuccess,
    required this.financePositive,
    required this.financeNegative,
    required this.accentLink,
    required this.surfaceElevated,
    required this.border,
  });

  static const light = KeepSyncThemeExt(
    success: KeepSyncColors.turf,
    onSuccess: KeepSyncColors.white,
    financePositive: KeepSyncColors.financePositiveLight,
    financeNegative: KeepSyncColors.financeNegativeLight,
    accentLink: KeepSyncColors.pitchBlue,
    surfaceElevated: KeepSyncColors.white,
    border: KeepSyncColors.borderLight,
  );

  static const dark = KeepSyncThemeExt(
    success: KeepSyncColors.turf,
    onSuccess: KeepSyncColors.white,
    financePositive: KeepSyncColors.financePositiveDark,
    financeNegative: KeepSyncColors.financeNegativeDark,
    accentLink: KeepSyncColors.pitchBlue,
    surfaceElevated: KeepSyncColors.ink2,
    border: KeepSyncColors.borderDark,
  );

  @override
  KeepSyncThemeExt copyWith({
    Color? success,
    Color? onSuccess,
    Color? financePositive,
    Color? financeNegative,
    Color? accentLink,
    Color? surfaceElevated,
    Color? border,
  }) {
    return KeepSyncThemeExt(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      financePositive: financePositive ?? this.financePositive,
      financeNegative: financeNegative ?? this.financeNegative,
      accentLink: accentLink ?? this.accentLink,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
    );
  }

  @override
  KeepSyncThemeExt lerp(ThemeExtension<KeepSyncThemeExt>? other, double t) {
    if (other is! KeepSyncThemeExt) return this;
    return KeepSyncThemeExt(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      financePositive:
          Color.lerp(financePositive, other.financePositive, t)!,
      financeNegative:
          Color.lerp(financeNegative, other.financeNegative, t)!,
      accentLink: Color.lerp(accentLink, other.accentLink, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension KeepSyncThemeContext on BuildContext {
  KeepSyncThemeExt get ks {
    return Theme.of(this).extension<KeepSyncThemeExt>() ?? KeepSyncThemeExt.light;
  }
}
