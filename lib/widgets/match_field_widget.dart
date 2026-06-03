import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/post_match.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';

/// Cancha con jugadores posicionados (coordenadas normalizadas 0–1).
class MatchFieldWidget extends StatelessWidget {
  final List<PostMatchLineupRow> players;
  final Map<int, Offset> slots;
  final String? formation;
  final bool compact;
  final bool showFormationLabel;
  final void Function(int userId)? onPlayerTap;
  final void Function(int userId, Offset normalizedPosition)? onSlotMoved;

  const MatchFieldWidget({
    super.key,
    required this.players,
    required this.slots,
    this.formation,
    this.compact = false,
    this.showFormationLabel = true,
    this.onPlayerTap,
    this.onSlotMoved,
  });

  @override
  Widget build(BuildContext context) {
    final showLabel =
        showFormationLabel && formation != null && formation!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

        if (bounded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLabel) _formationHeader(context),
              Expanded(
                child: _PitchStack(
                  players: players,
                  slots: slots,
                  compact: compact,
                  onPlayerTap: onPlayerTap,
                  onSlotMoved: onSlotMoved,
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel) _formationHeader(context),
            AspectRatio(
              aspectRatio: compact ? 1.5 : 0.68,
              child: _PitchStack(
                players: players,
                slots: slots,
                compact: compact,
                onPlayerTap: onPlayerTap,
                onSlotMoved: onSlotMoved,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _formationHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.sports_soccer, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Táctica: $formation',
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchStack extends StatelessWidget {
  final List<PostMatchLineupRow> players;
  final Map<int, Offset> slots;
  final bool compact;
  final void Function(int userId)? onPlayerTap;
  final void Function(int userId, Offset normalizedPosition)? onSlotMoved;

  const _PitchStack({
    required this.players,
    required this.slots,
    required this.compact,
    this.onPlayerTap,
    this.onSlotMoved,
  });

  @override
  Widget build(BuildContext context) {
    final placed = players
        .where((p) => p.isStarter || slots.containsKey(p.userId))
        .where((p) => slots.containsKey(p.userId))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final avatarR = compact ? 14.0 : 20.0;
        final marker = avatarR * 2 + 4;

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _PitchPainter(),
              size: Size(w, h),
            ),
            ...placed.map((p) {
              final pos = slots[p.userId]!;
              final left = (pos.dx * w) - avatarR;
              final top = (pos.dy * h) - avatarR;
              return Positioned(
                left: left.clamp(0, w - marker),
                top: top.clamp(0, h - marker),
                child: GestureDetector(
                  onTap: onPlayerTap != null
                      ? () => onPlayerTap!(p.userId)
                      : null,
                  onPanUpdate: onSlotMoved != null
                      ? (d) {
                          final nx =
                              ((pos.dx * w) + d.delta.dx) / w;
                          final ny =
                              ((pos.dy * h) + d.delta.dy) / h;
                          onSlotMoved!(
                            p.userId,
                            Offset(
                              nx.clamp(0.05, 0.95),
                              ny.clamp(0.05, 0.95),
                            ),
                          );
                        }
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatar(
                        avatarUrl: p.avatarUrl,
                        displayName: p.userName,
                        radius: avatarR,
                        badgeText: p.jerseyNumber?.toString(),
                      ),
                      if (!compact && h > 120)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: marker + 16),
                          child: Container(
                            margin: const EdgeInsets.only(top: 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              p.userName.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final grass = Paint()..color = const Color(0xFF2D5A27);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      grass,
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      line,
    );
    canvas.drawLine(
      Offset(size.width / 2, 4),
      Offset(size.width / 2, size.height - 4),
      line,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.12,
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        4,
        size.width * 0.5,
        size.height * 0.18,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height - 4 - size.height * 0.18,
        size.width * 0.5,
        size.height * 0.18,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Posiciones por defecto según formación (x,y normalizados, y=0 arquero).
Map<int, Offset> defaultSlotsForFormation(
  String formation,
  List<int> starterUserIds,
) {
  final templates = <String, List<Offset>>{
    '4-4-2': [
      const Offset(0.5, 0.92),
      const Offset(0.15, 0.72),
      const Offset(0.38, 0.72),
      const Offset(0.62, 0.72),
      const Offset(0.85, 0.72),
      const Offset(0.2, 0.48),
      const Offset(0.4, 0.48),
      const Offset(0.6, 0.48),
      const Offset(0.8, 0.48),
      const Offset(0.35, 0.22),
      const Offset(0.65, 0.22),
    ],
    '4-3-3': [
      const Offset(0.5, 0.92),
      const Offset(0.15, 0.72),
      const Offset(0.38, 0.72),
      const Offset(0.62, 0.72),
      const Offset(0.85, 0.72),
      const Offset(0.25, 0.5),
      const Offset(0.5, 0.48),
      const Offset(0.75, 0.5),
      const Offset(0.2, 0.22),
      const Offset(0.5, 0.2),
      const Offset(0.8, 0.22),
    ],
    '3-5-2': [
      const Offset(0.5, 0.92),
      const Offset(0.25, 0.75),
      const Offset(0.5, 0.75),
      const Offset(0.75, 0.75),
      const Offset(0.12, 0.52),
      const Offset(0.3, 0.48),
      const Offset(0.5, 0.5),
      const Offset(0.7, 0.48),
      const Offset(0.88, 0.52),
      const Offset(0.38, 0.22),
      const Offset(0.62, 0.22),
    ],
  };

  final pts = templates[formation] ?? templates['4-4-2']!;
  final map = <int, Offset>{};
  for (var i = 0; i < starterUserIds.length && i < pts.length; i++) {
    map[starterUserIds[i]] = pts[i];
  }
  return map;
}
