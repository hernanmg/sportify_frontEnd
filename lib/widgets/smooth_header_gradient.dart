import 'package:flutter/material.dart';

/// Cabecera con degradado suave (evita bandas/pixelado al estirar SliverAppBar).
class SmoothHeaderGradient extends StatelessWidget {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget? child;

  const SmoothHeaderGradient({
    super.key,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.child,
  });

  factory SmoothHeaderGradient.green() {
    return SmoothHeaderGradient(
      colors: const [
        Color(0xFF1B5E20),
        Color(0xFF2E7D32),
        Color(0xFF43A047),
        Color(0xFF66BB6A),
      ],
    );
  }

  factory SmoothHeaderGradient.primary(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return SmoothHeaderGradient(
      colors: [
        hsl.withLightness((hsl.lightness * 0.72).clamp(0.0, 1.0)).toColor(),
        primary,
        hsl.withLightness((hsl.lightness * 1.08).clamp(0.0, 1.0)).toColor(),
        hsl.withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
            .withLightness((hsl.lightness * 0.95).clamp(0.0, 1.0))
            .toColor(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: List.generate(
            colors.length,
            (i) => i / (colors.length - 1),
          ),
        ),
      ),
      child: child,
    );
  }
}
