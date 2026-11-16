import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/theme/keepsync_colors.dart';

/// Cabecera con degradado suave (evita bandas/pixelado al estirar SliverAppBar).
class SmoothHeaderGradient extends StatelessWidget {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget? child;

  const SmoothHeaderGradient({
    super.key,
    required this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.child,
  });

  /// Degradado marca KeepSync (Ink → Ink3).
  factory SmoothHeaderGradient.ink({Widget? child}) {
    return SmoothHeaderGradient(
      colors: _densify(const [
        KeepSyncColors.ink,
        KeepSyncColors.ink2,
        KeepSyncColors.ink3,
        KeepSyncColors.ink2,
        KeepSyncColors.ink,
      ]),
      child: child,
    );
  }

  @Deprecated('Usar SmoothHeaderGradient.ink')
  factory SmoothHeaderGradient.green({Widget? child}) {
    return SmoothHeaderGradient.ink(child: child);
  }

  factory SmoothHeaderGradient.primary(Color primary, {Widget? child}) {
    final hsl = HSLColor.fromColor(primary);
    return SmoothHeaderGradient(
      colors: _densify([
        hsl.withLightness((hsl.lightness * 0.72).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness * 0.88).clamp(0.0, 1.0)).toColor(),
        primary,
        hsl.withLightness((hsl.lightness * 1.05).clamp(0.0, 1.0)).toColor(),
        hsl
            .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
            .withLightness((hsl.lightness * 0.95).clamp(0.0, 1.0))
            .toColor(),
      ]),
      child: child,
    );
  }

  /// Interpola colores clave para reducir bandas en pantallas de 16 bits.
  static List<Color> _densify(List<Color> keyColors, {int steps = 6}) {
    if (keyColors.length < 2) return keyColors;
    final out = <Color>[];
    for (var i = 0; i < keyColors.length - 1; i++) {
      for (var s = 0; s < steps; s++) {
        out.add(Color.lerp(keyColors[i], keyColors[i + 1], s / steps)!);
      }
    }
    out.add(keyColors.last);
    return out;
  }

  BoxDecoration get _decoration => BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: List.generate(
            colors.length,
            (i) => i / (colors.length - 1),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return DecoratedBox(
        decoration: _decoration,
        child: child,
      );
    }
    return DecoratedBox(
      decoration: _decoration,
      child: const SizedBox.expand(),
    );
  }
}
