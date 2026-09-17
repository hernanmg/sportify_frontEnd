import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';

class SeasonSelectorChip extends StatelessWidget {
  const SeasonSelectorChip({super.key});

  Future<void> _configureDates(BuildContext context) async {
    final season = context.read<SeasonProvider>();
    final workspace = context.read<ActiveWorkspaceProvider>();
    final teamId = workspace.teamId ?? season.teamId;
    if (teamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná un equipo activo para configurar el torneo'),
        ),
      );
      return;
    }
    await season.bindTeam(teamId);

    var start = season.startDate;
    var end = season.endDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final fmt = DateFormat('dd/MM/yyyy');
          return AlertDialog(
            title: Text('Torneo · ${season.season}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Estas fechas se guardan en el servidor y las ven '
                  'todos los admins/DT del equipo. Al vencer, Finanzas avisa '
                  'para el cierre de caja.',
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Desde'),
                  subtitle:
                      Text(start != null ? fmt.format(start!) : 'Sin fecha'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setLocal(() => start = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hasta'),
                  subtitle: Text(end != null ? fmt.format(end!) : 'Sin fecha'),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: end ?? start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setLocal(() => end = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await season.setSeasonDates(start: null, end: null);
                    if (ctx.mounted) Navigator.pop(ctx, false);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Limpiar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      try {
        await season.setSeasonDates(start: start, end: end);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fechas del torneo guardadas en el equipo')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SeasonProvider, ActiveWorkspaceProvider>(
      builder: (context, season, workspace, _) {
        // Mantener fechas del equipo activo sincronizadas.
        final tid = workspace.teamId;
        if (tid != null && tid != season.teamId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) season.bindTeam(tid);
          });
        }

        final subtitle = season.hasDateRange
            ? ' · ${DateFormat('dd/MM').format(season.startDate!)}'
                '-${DateFormat('dd/MM').format(season.endDate!)}'
            : '';
        return PopupMenuButton<String>(
          tooltip: 'Temporada activa',
          onSelected: (value) async {
            if (value == '__dates__') {
              await _configureDates(context);
              return;
            }
            await season.setSeason(value);
          },
          itemBuilder: (_) => [
            ...season.availableSeasons.map(
              (s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == season.season)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(s),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: '__dates__',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.date_range),
                title: Text('Desde / hasta del torneo'),
                dense: true,
              ),
            ),
          ],
          child: Chip(
            avatar: Icon(
              season.isSeasonEnded ? Icons.warning_amber : Icons.calendar_month,
              size: 18,
              color: season.isSeasonEnded ? Colors.orange : null,
            ),
            label: Text(
              '${season.season}$subtitle',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
