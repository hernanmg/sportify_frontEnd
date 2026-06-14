import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/post_match.dart';
import 'package:sportify_amateur/widgets/match_field_widget.dart';

/// Vista previa estática de la pantalla de alineación (sin partido real).
class LineupHelpPreview extends StatelessWidget {
  const LineupHelpPreview({super.key});

  static final _demoPlayers = [
    PostMatchLineupRow(
      userId: 1,
      userName: 'Arquero',
      jerseyNumber: 1,
      role: 'player',
      isStarter: true,
      confirmed: true,
    ),
    PostMatchLineupRow(
      userId: 2,
      userName: 'Defensa',
      jerseyNumber: 4,
      role: 'player',
      isStarter: true,
      confirmed: true,
    ),
    PostMatchLineupRow(
      userId: 3,
      userName: 'Medio',
      jerseyNumber: 8,
      role: 'player',
      isStarter: true,
      confirmed: true,
    ),
    PostMatchLineupRow(
      userId: 4,
      userName: 'Delantero',
      jerseyNumber: 9,
      role: 'player',
      isStarter: true,
      confirmed: true,
    ),
  ];

  static final _demoSlots = {
    1: const Offset(0.5, 0.9),
    2: const Offset(0.3, 0.65),
    3: const Offset(0.7, 0.45),
    4: const Offset(0.5, 0.22),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Así se ve la pantalla de alineación',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 0.68,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              child: MatchFieldWidget(
                players: _demoPlayers,
                slots: _demoSlots,
                formation: '4-4-2',
                compact: true,
                showFormationLabel: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ejemplo ilustrativo · DT/cuerpo técnico edita; jugadores solo ven la formación.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
