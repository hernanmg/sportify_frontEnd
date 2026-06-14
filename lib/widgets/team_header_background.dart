import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/team_branding_provider.dart';
import 'package:sportify_amateur/core/widgets/image_from_url_or_data.dart';
import 'package:sportify_amateur/widgets/smooth_header_gradient.dart';

/// Escudo centrado como marca de agua en el fondo de cualquier pantalla.
class TeamBrandingBackdrop extends StatelessWidget {
  final double size;
  final double opacity;

  const TeamBrandingBackdrop({
    super.key,
    this.size = 260,
    this.opacity = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<TeamBrandingProvider>();
    if (!branding.hasLogo) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: ImageFromUrlOrData(
            imageUrl: branding.logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: const SizedBox.shrink(),
            errorWidget: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Degradado de cabecera con escudo del equipo como marca de agua (solo Inicio).
class TeamHeaderBackground extends StatelessWidget {
  final Color primary;
  final bool useGreenGradient;
  final Widget? child;

  const TeamHeaderBackground({
    super.key,
    required this.primary,
    this.useGreenGradient = false,
    this.child,
  });

  Widget _gradient({Widget? content}) {
    if (useGreenGradient) {
      return SmoothHeaderGradient.green(child: content);
    }
    return SmoothHeaderGradient.primary(primary, child: content);
  }

  Widget _logoWatermark(String logoUrl, {double size = 140, double opacity = 0.22}) {
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: ImageFromUrlOrData(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            width: size,
            height: size,
            placeholder: const SizedBox.shrink(),
            errorWidget: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<TeamBrandingProvider>();
    final logoUrl = branding.logoUrl;

    if (!branding.hasLogo) {
      return _gradient(content: child);
    }

    if (child != null) {
      return _gradient(
        content: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _logoWatermark(logoUrl!)),
            child!,
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _gradient(),
        Positioned.fill(child: _logoWatermark(logoUrl!)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
