import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';

class SeasonSelectorChip extends StatelessWidget {
  const SeasonSelectorChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SeasonProvider>(
      builder: (context, season, _) {
        return PopupMenuButton<String>(
          tooltip: 'Temporada activa',
          child: Chip(
            avatar: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              season.season,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          onSelected: season.setSeason,
          itemBuilder: (_) => season.availableSeasons
              .map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Text(s),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
