import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/team_branding_provider.dart';
import 'package:sportify_amateur/core/widgets/image_from_url_or_data.dart';
import 'package:sportify_amateur/models/board_stroke.dart';
import 'package:sportify_amateur/models/post_match.dart';
import 'package:sportify_amateur/widgets/field_drawing_overlay.dart';
import 'package:sportify_amateur/widgets/match_field_widget.dart';

/// Cancha estilo Google Sports: marcador, fotos con nota y formación al pie.
class GoogleStyleLineupField extends StatelessWidget {
  final List<PostMatchLineupRow> players;
  final Map<int, Offset> slots;
  final String? formation;
  final PostMatchResult matchResult;
  final String? opponentName;
  final String? teamName;
  final String? teamLogoUrl;
  final bool isCompleted;
  final List<PostMatchPlayerRow> ratings;
  final List<PostMatchStatsRow> stats;
  final List<BoardStroke> boardStrokes;

  const GoogleStyleLineupField({
    super.key,
    required this.players,
    required this.slots,
    this.formation,
    required this.matchResult,
    this.opponentName,
    this.teamName,
    this.teamLogoUrl,
    this.isCompleted = false,
    this.ratings = const [],
    this.stats = const [],
    this.boardStrokes = const [],
  });

  factory GoogleStyleLineupField.fromPostMatch(
    PostMatchData data, {
    String? teamName,
    String? teamLogoUrl,
  }) {
    final starterIds =
        data.lineup.where((p) => p.isStarter).map((p) => p.userId).toList();
    final resolvedSlots = data.lineupSlots.isNotEmpty
        ? data.lineupSlots
        : defaultSlotsForFormation(data.formation ?? '4-4-2', starterIds);

    return GoogleStyleLineupField(
      players: data.lineup,
      slots: resolvedSlots,
      formation: data.formation,
      matchResult: data.matchResult,
      opponentName: data.opponentName,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      isCompleted: data.isCompleted,
      ratings: data.targets,
      stats: data.stats,
      boardStrokes: data.boardStrokes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<TeamBrandingProvider>();
    final resolvedTeam = teamName ?? branding.team?.name ?? 'Mi equipo';
    final resolvedLogo = teamLogoUrl ?? branding.logoUrl;

    final placed = players
        .where((p) => p.isStarter || slots.containsKey(p.userId))
        .where((p) => slots.containsKey(p.userId))
        .toList();

    final ratingsByUser = {for (final r in ratings) r.userId: r};
    final statsByUser = {for (final s in stats) s.userId: s};

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFF0D1117),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScoreHeader(
              matchResult: matchResult,
              opponentName: opponentName ?? 'Rival',
              teamName: resolvedTeam,
              teamLogoUrl: resolvedLogo,
              isCompleted: isCompleted,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: const _GooglePitchPainter(),
                        size: Size(w, h),
                      ),
                      ...placed.map((p) {
                        final pos = slots[p.userId]!;
                        return _GooglePlayerMarker(
                          player: p,
                          normalizedPosition: pos,
                          fieldWidth: w,
                          fieldHeight: h,
                          rating: ratingsByUser[p.userId]?.displayScore,
                          matchStats: statsByUser[p.userId],
                        );
                      }),
                      if (boardStrokes.isNotEmpty)
                        FieldDrawingOverlay(
                          strokes: boardStrokes,
                          drawEnabled: false,
                          onStrokesChanged: (_) {},
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _TeamFooter(
                          teamName: resolvedTeam,
                          teamLogoUrl: resolvedLogo,
                          formation: formation ?? '4-4-2',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final PostMatchResult matchResult;
  final String opponentName;
  final String teamName;
  final String? teamLogoUrl;
  final bool isCompleted;

  const _ScoreHeader({
    required this.matchResult,
    required this.opponentName,
    required this.teamName,
    this.teamLogoUrl,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore =
        matchResult.teamScore != null && matchResult.opponentScore != null;
    final us = matchResult.isHomeMatch
        ? matchResult.teamScore
        : matchResult.opponentScore;
    final them = matchResult.isHomeMatch
        ? matchResult.opponentScore
        : matchResult.teamScore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _HeaderTeam(
                  name: matchResult.isHomeMatch ? teamName : opponentName,
                  logoUrl: matchResult.isHomeMatch ? teamLogoUrl : null,
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  hasScore ? '$us - $them' : 'vs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Flexible(
                child: _HeaderTeam(
                  name: matchResult.isHomeMatch ? opponentName : teamName,
                  logoUrl: matchResult.isHomeMatch ? null : teamLogoUrl,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Fin',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderTeam extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final bool alignEnd;

  const _HeaderTeam({
    required this.name,
    this.logoUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _MiniLogo(url: logoUrl);
    final label = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [Flexible(child: label), const SizedBox(width: 6), logo]
          : [logo, const SizedBox(width: 6), Flexible(child: label)],
    );
  }
}

class _MiniLogo extends StatelessWidget {
  final String? url;

  const _MiniLogo({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.trim().isNotEmpty
          ? ImageFromUrlOrData(imageUrl: url, fit: BoxFit.cover)
          : const Icon(Icons.sports_soccer, size: 14, color: Colors.white54),
    );
  }
}

class _TeamFooter extends StatelessWidget {
  final String teamName;
  final String? teamLogoUrl;
  final String formation;

  const _TeamFooter({
    required this.teamName,
    this.teamLogoUrl,
    required this.formation,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
        child: Row(
          children: [
            _MiniLogo(url: teamLogoUrl),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                formation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GooglePlayerMarker extends StatelessWidget {
  final PostMatchLineupRow player;
  final Offset normalizedPosition;
  final double fieldWidth;
  final double fieldHeight;
  final double? rating;
  final PostMatchStatsRow? matchStats;

  const _GooglePlayerMarker({
    required this.player,
    required this.normalizedPosition,
    required this.fieldWidth,
    required this.fieldHeight,
    this.rating,
    this.matchStats,
  });

  @override
  Widget build(BuildContext context) {
    const photoSize = 46.0;
    const markerW = 62.0;
    const markerH = 78.0;

    final left = (normalizedPosition.dx * fieldWidth) - (markerW / 2);
    final top = (normalizedPosition.dy * fieldHeight) - (photoSize / 2);

    return Positioned(
      left: left.clamp(0, fieldWidth - markerW),
      top: top.clamp(0, fieldHeight - markerH),
      width: markerW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: photoSize,
            height: photoSize + 8,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                _SquarePlayerPhoto(
                  avatarUrl: player.avatarUrl,
                  displayName: player.userName,
                  size: photoSize,
                ),
                if (matchStats != null && matchStats!.goals > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: _EventBadge(
                      icon: Icons.sports_soccer,
                      color: Colors.white,
                      background: Colors.black87,
                    ),
                  ),
                if (matchStats != null && matchStats!.yellowCards > 0)
                  Positioned(
                    top: -2,
                    left: -4,
                    child: _EventBadge(
                      icon: Icons.square,
                      color: Colors.amber,
                      background: Colors.black87,
                      iconSize: 12,
                    ),
                  ),
                if (matchStats != null && matchStats!.redCards > 0)
                  Positioned(
                    top: 10,
                    left: -4,
                    child: _EventBadge(
                      icon: Icons.square,
                      color: Colors.red,
                      background: Colors.black87,
                      iconSize: 12,
                    ),
                  ),
                if (rating != null)
                  Positioned(
                    bottom: 0,
                    child: _RatingBadge(score: rating!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _playerLabel(player),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquarePlayerPhoto extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;

  const _SquarePlayerPhoto({
    required this.avatarUrl,
    required this.displayName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? ImageFromUrlOrData(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: _initialTile(initial),
            )
          : _initialTile(initial),
    );
  }

  Widget _initialTile(String initial) {
    return ColoredBox(
      color: const Color(0xFF37474F),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double score;

  const _RatingBadge({required this.score});

  Color get _color {
    if (score >= 7.0) return const Color(0xFF00C853);
    if (score >= 6.0) return const Color(0xFF9E9D24);
    if (score >= 5.0) return const Color(0xFFFF8F00);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double iconSize;

  const _EventBadge({
    required this.icon,
    required this.color,
    required this.background,
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

String _playerLabel(PostMatchLineupRow player) {
  final parts = player.userName.trim().split(RegExp(r'\s+'));
  final jersey = player.jerseyNumber?.toString() ?? '';
  if (parts.isEmpty) return jersey;
  if (parts.length == 1) {
    return jersey.isEmpty ? parts.first : '$jersey ${parts.first}';
  }
  final firstInitial = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last;
  final short = '$firstInitial. $last';
  return jersey.isEmpty ? short : '$jersey $short';
}

class _GooglePitchPainter extends CustomPainter {
  const _GooglePitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final grass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E4620), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(rect);
    canvas.drawRect(rect, grass);

    _drawStripes(canvas, size);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const m = 6.0;
    final field = Rect.fromLTWH(m, m, size.width - m * 2, size.height - m * 2);
    canvas.drawRect(field, line);

    final boxW = field.width * 0.52;
    final boxH = field.height * 0.2;
    final boxLeft = field.left + (field.width - boxW) / 2;

    final bottomBox = Rect.fromLTWH(
      boxLeft,
      field.bottom - boxH,
      boxW,
      boxH,
    );
    canvas.drawRect(bottomBox, line);

    final goalLine = Paint()
      ..color = line.color
      ..style = line.style
      ..strokeWidth = 2.5;
    final goalW = field.width * 0.24;
    final goalH = field.height * 0.035;
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - goalW / 2,
        field.bottom - goalH,
        goalW,
        goalH,
      ),
      goalLine,
    );

    _drawPenaltyArc(canvas, bottomBox, line, arcDown: false);
  }

  void _drawStripes(Canvas canvas, Size size) {
    const stripeCount = 10;
    final stripeW = size.width / stripeCount;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    for (var i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeW, 0, stripeW, size.height),
        paint,
      );
    }
  }

  void _drawPenaltyArc(
    Canvas canvas,
    Rect box,
    Paint line, {
    required bool arcDown,
  }) {
    final center = Offset(box.center.dx, arcDown ? box.bottom : box.top);
    final radius = box.width * 0.16;
    final path = Path();
    if (arcDown) {
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        math.pi,
      );
    } else {
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
      );
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
