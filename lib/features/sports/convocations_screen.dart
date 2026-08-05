import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/core/services/convocation_pdf_service.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/core/utils/sport_event_category.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/features/sports/convocation_form_screen.dart';
import 'package:sportify_amateur/features/sports/post_match_screen.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
import 'package:sportify_amateur/models/player_eligibility.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class ConvocationsScreen extends StatefulWidget {
  const ConvocationsScreen({super.key});

  @override
  State<ConvocationsScreen> createState() => ConvocationsScreenState();
}

class ConvocationsScreenState extends State<ConvocationsScreen> {
  final _convocationsService = ConvocationsService();
  final _pdfService = ConvocationPdfService();

  List<SportEvent> _convocations = [];
  bool _loading = true;
  String _filter = 'all';
  String? _userRole;
  int? _loadedForTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ws = context.read<ActiveWorkspaceProvider>();
      ws.addListener(_onWorkspaceChanged);
      ws.load().then((_) => _load());
    });
  }

  @override
  void dispose() {
    try {
      context.read<ActiveWorkspaceProvider>().removeListener(_onWorkspaceChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onWorkspaceChanged() {
    final teamId = context.read<ActiveWorkspaceProvider>().teamId;
    if (teamId != _loadedForTeamId && mounted) {
      _load();
    }
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final workspace = context.read<ActiveWorkspaceProvider>();
    final teamId = workspace.teamId;

    setState(() => _loading = true);
    try {
      final role = await AuthStorageService().getRole();
      List<SportEvent> list = [];
      if (teamId != null) {
        list = await _convocationsService.getAllConvocations(teamId: teamId);
      }
      if (!mounted) return;
      setState(() {
        _convocations = list;
        _userRole = role;
        _loadedForTeamId = teamId;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<SportEvent> _filteredFor(int? categoryId) {
    Iterable<SportEvent> list = _convocations;
    if (categoryId != null) {
      list = list.where((c) => c.matchesCategoryFilter(categoryId));
    }
    switch (_filter) {
      case 'sent':
        return ConvocationsService.filterSent(list.toList());
      case 'draft':
        return ConvocationsService.filterDrafts(list.toList());
      case 'official':
        return ConvocationsService.filterByMatchType(list.toList(), true);
      case 'friendly':
        return ConvocationsService.filterByMatchType(list.toList(), false);
      default:
        return list.toList();
    }
  }

  List<SportEvent> get _sentWithPending {
    return ConvocationsService.filterSent(_convocations)
        .where((c) => c.isUpcoming && c.pendingCount > 0)
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  int get _totalPendingResponses =>
      _sentWithPending.fold(0, (sum, c) => sum + c.pendingCount);

  Future<void> _openCreate({bool official = false}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConvocationFormScreen(isOfficial: official),
      ),
    );
    if (result == true) await _load();
  }

  Future<void> _deleteConvocation(SportEvent c, {bool silent = false}) async {
    if (!silent) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar convocatoria'),
          content: Text(
            '¿Eliminar "${c.title}"? Se borrará el partido y sus datos asociados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await _convocationsService.deleteConvocation(c.id);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convocatoria eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      await _load();
    }
  }

  Future<void> _send(SportEvent c) async {
    try {
      await _convocationsService.sendConvocation(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convocatoria enviada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addPlayersToConvocation(SportEvent c) async {
    try {
      final results = await Future.wait([
        _convocationsService.getEligibleRoster(c.id),
        _convocationsService.getConvocationResponses(c.id),
      ]);
      final eligible = results[0] as List<PlayerEligibility>;
      final responses = results[1] as List<EventParticipant>;
      final convokedIds = responses
          .where((p) => p.isConvoked)
          .map((p) => p.userId)
          .toSet();
      final available =
          eligible.where((e) => !convokedIds.contains(e.userId)).toList();

      if (!mounted) return;
      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay jugadores disponibles para sumar'),
          ),
        );
        return;
      }

      final selected = <int>{};
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Sumar jugadores'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elegí jugadores del plantel que aún no están convocados. '
                    'Recibirán la notificación de convocatoria.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final p = available[i];
                        return CheckboxListTile(
                          dense: true,
                          value: selected.contains(p.userId),
                          secondary: PlayerAvatar(
                            avatarUrl: p.avatarUrl,
                            displayName: p.playerName,
                            radius: 16,
                          ),
                          title: Text(p.playerName),
                          subtitle: Text(
                            [
                              if (p.jerseyNumber != null) '#${p.jerseyNumber}',
                              if (p.category != null) p.category,
                              p.statusLabel,
                            ].whereType<String>().join(' · '),
                          ),
                          onChanged: (v) {
                            setDialogState(() {
                              if (v == true) {
                                selected.add(p.userId);
                              } else {
                                selected.remove(p.userId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: Text('Sumar (${selected.length})'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || selected.isEmpty) return;

      final result = await _convocationsService.addConvokedPlayers(
        c.id,
        selected.toList(),
      );

      if (!mounted) return;
      final msg = result.added.isEmpty
          ? 'Los jugadores seleccionados ya estaban convocados'
          : 'Se sumaron ${result.added.length} jugador(es)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _remindPending(SportEvent c) async {
    try {
      final count = await _convocationsService.remindPendingConvocation(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Recordatorio enviado a $count jugador(es)'
                : 'No hay jugadores pendientes',
          ),
          backgroundColor: count > 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showResponses(SportEvent c) async {
    try {
      final stats = await _convocationsService.getConvocationStats(c.id);
      final responses =
          await _convocationsService.getConvocationResponses(c.id);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(c.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convocados: ${stats.convoked} · Confirmados: ${stats.confirmed} · Pendientes: ${stats.pending}',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: responses.map((p) {
                      return ListTile(
                        dense: true,
                        leading: PlayerAvatar(
                          avatarUrl: p.avatarUrl,
                          displayName: p.userName,
                          radius: 16,
                        ),
                        title: Text(p.userName),
                        subtitle: Text(
                          '${p.statusDisplayName}${p.eligibilityDetail != null ? ' · ${p.eligibilityDetail}' : ''}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (stats.pending > 0 &&
                UserCapabilities.canManageConvocations(_userRole))
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _remindPending(c);
                },
                child: const Text('Recordar pendientes'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<ActiveWorkspaceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredFor(workspace.categoryId);
    final isDark = scheme.brightness == Brightness.dark;
    final bannerBg =
        isDark ? scheme.tertiaryContainer : Colors.orange.shade50;
    final bannerFg =
        isDark ? scheme.onTertiaryContainer : Colors.orange.shade900;
    final bannerAction =
        isDark ? scheme.onTertiaryContainer : Colors.orange.shade800;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (workspace.team != null && workspace.hasMultipleCategories)
                DropdownButtonFormField<int?>(
                  initialValue: workspace.categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...workspace.categories.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => workspace.setCategoryId(v),
                ),
              if (workspace.team == null && workspace.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Seleccioná tu equipo activo desde Inicio o Perfil.',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filter,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todas')),
                        DropdownMenuItem(
                          value: 'sent',
                          child: Text('Enviadas'),
                        ),
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Borradores'),
                        ),
                        DropdownMenuItem(
                          value: 'official',
                          child: Text('Oficiales'),
                        ),
                        DropdownMenuItem(
                          value: 'friendly',
                          child: Text('Amistosos'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _filter = v ?? 'all'),
                    ),
                  ),
                  if (UserCapabilities.canManageConvocations(_userRole))
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.add_circle_outline),
                      onSelected: (v) {
                        if (v == 'official') {
                          _openCreate(official: true);
                        } else {
                          _openCreate(official: false);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'friendly',
                          child: Text('Amistoso'),
                        ),
                        PopupMenuItem(
                          value: 'official',
                          child: Text('Oficial'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!_loading &&
            UserCapabilities.canManageConvocations(_userRole) &&
            _sentWithPending.isNotEmpty)
          MaterialBanner(
            backgroundColor: bannerBg,
            leading: Icon(Icons.notifications_active, color: bannerFg),
            content: Text(
              _sentWithPending.length == 1
                  ? '${_sentWithPending.first.title}: ${_sentWithPending.first.pendingCount} sin confirmar'
                  : '$_totalPendingResponses confirmación(es) pendiente(s) en ${_sentWithPending.length} convocatoria(s)',
              style: TextStyle(color: bannerFg),
            ),
            actions: [
              TextButton(
                onPressed: () => _remindPending(_sentWithPending.first),
                style: TextButton.styleFrom(foregroundColor: bannerAction),
                child: const Text('Recordar'),
              ),
              TextButton(
                onPressed: () => _showResponses(_sentWithPending.first),
                style: TextButton.styleFrom(foregroundColor: bannerAction),
                child: const Text('Ver detalle'),
              ),
              TextButton(
                onPressed: () => setState(() => _filter = 'sent'),
                style: TextButton.styleFrom(foregroundColor: bannerAction),
                child: const Text('Ver enviadas'),
              ),
            ],
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('No hay convocatorias'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            final isDraft =
                                c.status == SportEventStatus.draft;
                            final dateStr =
                                DateFormat('dd/MM/yyyy HH:mm').format(
                              c.eventDate,
                            );
                            final card = Card(
                              child: ExpansionTile(
                                leading: Icon(
                                  c.isOfficialMatch
                                      ? Icons.emoji_events
                                      : Icons.sports_soccer,
                                  color: isDraft
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                title: Text(c.title),
                                subtitle: Text(
                                  '${c.opponentName ?? 'Rival'} · $dateStr',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (c.location != null)
                                          Text('📍 ${c.location}'),
                                        if (c.courtNumber != null)
                                          Text('Cancha ${c.courtNumber}'),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            Chip(
                                              label: Text(
                                                isDraft
                                                    ? 'Borrador'
                                                    : 'Enviada',
                                              ),
                                              backgroundColor: isDraft
                                                  ? Colors.orange.shade100
                                                  : Colors.green.shade100,
                                            ),
                                            Chip(
                                              label: Text(
                                                c.isOfficialMatch
                                                    ? 'Oficial'
                                                    : 'Amistoso',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (!isDraft && canOpenPostMatch(c))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: FilledButton.tonalIcon(
                                                onPressed: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PostMatchScreen(
                                                        eventId: c.id,
                                                        eventTitle: c.title,
                                                      ),
                                                    ),
                                                  );
                                                  if (mounted) await _load();
                                                },
                                                icon: const Icon(
                                                  Icons.sports_soccer_outlined,
                                                ),
                                                label: const Text(
                                                  'Gestionar partido',
                                                ),
                                              ),
                                            ),
                                          ),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            if (c.canDeleteConvocation)
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _deleteConvocation(c),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                label: const Text('Eliminar'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                              ),
                                            if (isDraft)
                                              TextButton.icon(
                                                onPressed: () => _send(c),
                                                icon: const Icon(Icons.send),
                                                label: const Text('Enviar'),
                                              ),
                                            if (!isDraft &&
                                                UserCapabilities
                                                    .canAddToSentConvocation(
                                                  _userRole,
                                                ))
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _addPlayersToConvocation(c),
                                                icon: const Icon(
                                                  Icons.person_add_outlined,
                                                ),
                                                label: const Text(
                                                  'Sumar jugadores',
                                                ),
                                              ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _showResponses(c),
                                              icon: const Icon(Icons.people),
                                              label: const Text('Plantel'),
                                            ),
                                            if (!isDraft)
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.picture_as_pdf,
                                                ),
                                                tooltip: 'PDF / Compartir',
                                                onSelected: (action) async {
                                                  try {
                                                    if (action == 'preview') {
                                                      await _pdfService
                                                          .previewPdf(c.id);
                                                    } else {
                                                      await _pdfService
                                                          .sharePdf(c.id);
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'PDF: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                    value: 'preview',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.visibility,
                                                      ),
                                                      title: Text('Ver PDF'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'share',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.share,
                                                      ),
                                                      title: Text('Compartir'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (isDraft)
                                              TextButton.icon(
                                                onPressed: () async {
                                                  final r =
                                                      await Navigator.push<
                                                          bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ConvocationFormScreen(
                                                        existing: c,
                                                        isOfficial: c
                                                            .isOfficialMatch,
                                                      ),
                                                    ),
                                                  );
                                                  if (r == true) await _load();
                                                },
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Editar'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (!c.canDeleteConvocation) return card;
                            return Dismissible(
                              key: ValueKey('convocation-${c.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                margin: const EdgeInsets.only(bottom: 4),
                                color: Colors.red.shade400,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar convocatoria'),
                                    content: Text('¿Eliminar "${c.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                return ok == true;
                              },
                              onDismissed: (_) =>
                                  _deleteConvocation(c, silent: true),
                              child: card,
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
