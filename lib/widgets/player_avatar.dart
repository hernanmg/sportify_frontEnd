import 'package:flutter/material.dart';

/// Avatar de jugador: foto de perfil o inicial del nombre.
class PlayerAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final String? badgeText;

  const PlayerAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.badgeText,
  });

  String get _initial {
    final t = displayName.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;

    Widget avatar;
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          badgeText ?? _initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.85,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    if (badgeText != null && url != null && url.isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: CircleAvatar(
              radius: radius * 0.45,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                badgeText!,
                style: TextStyle(
                  fontSize: radius * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}
