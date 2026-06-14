import 'package:flutter/material.dart';
import 'package:sportify_amateur/widgets/team_header_background.dart';

/// Marca de agua del escudo en tabs principales (sin bloquear toques).
class TeamBrandedAppOverlay extends StatelessWidget {
  final Widget? child;

  const TeamBrandedAppOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (child != null) child!,
        const IgnorePointer(
          child: Center(
            child: TeamBrandingBackdrop(size: 280, opacity: 0.11),
          ),
        ),
      ],
    );
  }
}
