import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/onboarding_flags_service.dart';

/// Tour breve para DT la primera vez que abre la app tras el alta.
class DtGuidedTour {
  DtGuidedTour._();

  static bool _showing = false;

  static Future<void> maybeShow(BuildContext context, {String? role}) async {
    if (role != 'dt' || _showing || !context.mounted) return;

    final userId = await AuthStorageService().getUserId();
    if (userId == null) return;
    final done = await OnboardingFlagsService.instance.hasCompletedDtTour(userId);
    if (done || !context.mounted) return;

    _showing = true;
    try {
      await _runTour(context);
      await OnboardingFlagsService.instance.setDtTourCompleted(userId);
    } finally {
      _showing = false;
    }
  }

  static Future<void> _runTour(BuildContext context) async {
    final steps = [
      (
        title: 'Bienvenido, DT',
        body:
            'Desde el panel de Inicio ves el próximo partido, confirmaciones pendientes y jugadores con cuota pendiente.',
        icon: Icons.dashboard_customize,
      ),
      (
        title: 'Convocatorias',
        body:
            'En Deporte → Convocatorias podés crear partidos, usar el plantel anterior, titulares y enviar recordatorios solo a pendientes.',
        icon: Icons.campaign_outlined,
      ),
      (
        title: 'Asistencia en cancha',
        body:
            'Tomá lista sin señal: los cambios se guardan en el teléfono y se sincronizan cuando vuelve internet.',
        icon: Icons.fact_check_outlined,
      ),
      (
        title: 'Más opciones',
        body:
            'En el menú Más tenés Panel del equipo, Editar equipo, Informes y Cuotas del plantel.',
        icon: Icons.menu,
      ),
    ];

    for (var i = 0; i < steps.length; i++) {
      if (!context.mounted) return;
      final step = steps[i];
      final isLast = i == steps.length - 1;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: Icon(step.icon, size: 36, color: Colors.teal.shade700),
          title: Text(step.title),
          content: Text(step.body),
          actions: [
            if (!isLast)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Omitir'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isLast ? '¡Listo!' : 'Siguiente (${i + 1}/${steps.length})'),
            ),
          ],
        ),
      );
    }
  }
}
