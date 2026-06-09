import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Muestra el código de invitación con opciones de copiar y compartir (WhatsApp, etc.).
Future<void> showInviteCodeShareSheet(
  BuildContext context, {
  required String inviteCode,
  String? teamName,
}) async {
  final message = teamName != null && teamName.isNotEmpty
      ? 'Sumate a $teamName en Sportify Amateur. Código de invitación: $inviteCode'
      : 'Sumate a nuestro equipo en Sportify Amateur. Código de invitación: $inviteCode';

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            teamName != null ? 'Invitación a $teamName' : 'Código de invitación',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SelectableText(
            inviteCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compartilo por WhatsApp, email o el medio que prefieras.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await Share.share(message, subject: 'Invitación Sportify Amateur');
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir código'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteCode));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
          ),
        ],
      ),
    ),
  );
}
