import 'package:flutter/material.dart';

enum KeepSyncLogoVariant {
  /// Isotipo Volt + S (cuadrado).
  mark,
  /// Logo completo para fondos oscuros (texto claro).
  wordmarkOnDark,
  /// Logo completo para fondos claros (texto Ink).
  wordmarkOnLight,
}

class KeepSyncBrandLogo extends StatelessWidget {
  final KeepSyncLogoVariant variant;
  final double height;
  final BoxFit fit;

  const KeepSyncBrandLogo({
    super.key,
    this.variant = KeepSyncLogoVariant.mark,
    this.height = 40,
    this.fit = BoxFit.contain,
  });

  const KeepSyncBrandLogo.mark({super.key, this.height = 40, this.fit = BoxFit.contain})
      : variant = KeepSyncLogoVariant.mark;

  const KeepSyncBrandLogo.wordmarkOnDark({
    super.key,
    this.height = 36,
    this.fit = BoxFit.contain,
  }) : variant = KeepSyncLogoVariant.wordmarkOnDark;

  const KeepSyncBrandLogo.wordmarkOnLight({
    super.key,
    this.height = 36,
    this.fit = BoxFit.contain,
  }) : variant = KeepSyncLogoVariant.wordmarkOnLight;

  String get _asset {
    switch (variant) {
      case KeepSyncLogoVariant.mark:
        return 'assets/brand/isotipo.png';
      case KeepSyncLogoVariant.wordmarkOnDark:
        return 'assets/brand/logo-negativo.png';
      case KeepSyncLogoVariant.wordmarkOnLight:
        return 'assets/brand/logo-positivo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
