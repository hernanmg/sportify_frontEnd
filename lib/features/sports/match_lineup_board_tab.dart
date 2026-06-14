import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/services/post_match_service.dart';
import 'package:sportify_amateur/core/services/tactical_board_service.dart';
import 'package:sportify_amateur/models/board_stroke.dart';
import 'package:sportify_amateur/models/post_match.dart';
import 'package:sportify_amateur/models/tactical_board.dart';
import 'package:sportify_amateur/widgets/field_drawing_overlay.dart';
import 'package:sportify_amateur/widgets/match_field_widget.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';

class MatchLineupBoardTab extends StatefulWidget {
  final PostMatchData data;
  final PostMatchService service;
  final VoidCallback onUpdated;
  final void Function(String msg, {bool error}) onMessage;

  const MatchLineupBoardTab({
    super.key,
    required this.data,
    required this.service,
    required this.onUpdated,
    required this.onMessage,
  });

  @override
  State<MatchLineupBoardTab> createState() => _MatchLineupBoardTabState();
}

class _MatchLineupBoardTabState extends State<MatchLineupBoardTab> {
  static const _formations = ['4-4-2', '4-3-3', '3-5-2'];

  final _tacticalService = TacticalBoardService();
  final _fieldKey = GlobalKey();

  late String _formation;
  late Map<int, Offset> _slots;
  late List<BoardStroke> _strokes;
  bool _saving = false;
  bool _penEnabled = false;
  List<TacticalBoard> _savedBoards = [];
  bool _loadingBoards = false;
  bool _lineupModalOpen = false;
  StateSetter? _modalSetState;

  /// Actualiza estado local y, si hay modal abierto, refresca su UI también.
  void _syncLineupUi(VoidCallback mutate) {
    if (!mounted) return;
    setState(mutate);
    _modalSetState?.call(() {});
  }

  List<PostMatchLineupRow> get _confirmed =>
      widget.data.lineup.where((p) => p.confirmed).toList();

  bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 720;

  @override
  void initState() {
    super.initState();
    _formation = widget.data.formation ?? '4-4-2';
    _slots = Map.from(widget.data.lineupSlots);
    _strokes = List.from(widget.data.boardStrokes);
    if (_slots.isEmpty) {
      final starterIds = widget.data.lineup
          .where((p) => p.isStarter)
          .map((p) => p.userId)
          .toList();
      if (starterIds.isNotEmpty) {
        _slots = defaultSlotsForFormation(_formation, starterIds);
      }
    }
    _loadSavedBoards();
  }

  Future<void> _loadSavedBoards() async {
    setState(() => _loadingBoards = true);
    try {
      final boards = await _tacticalService.listByTeam(widget.data.teamId);
      if (mounted) setState(() => _savedBoards = boards);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingBoards = false);
    }
  }

  Future<void> _save() async {
    _syncLineupUi(() => _saving = true);
    try {
      final items = widget.data.lineup
          .map(
            (p) => {
              'userId': p.userId,
              'isStarter': _slots.containsKey(p.userId),
              'playingPosition': p.playingPosition,
              'role': p.role,
            },
          )
          .toList();
      await widget.service.updateLineup(
        widget.data.eventId,
        items: items,
        formation: _formation,
        lineupSlots: _slots,
        boardStrokes: _strokes,
      );
      widget.onMessage('Alineación guardada');
      widget.onUpdated();
    } catch (e) {
      widget.onMessage(PostMatchService.errorMessage(e), error: true);
    } finally {
      if (mounted) _syncLineupUi(() => _saving = false);
    }
  }

  void _applyFormation(String f, {bool notify = false}) {
    _syncLineupUi(() {
      _formation = f;
      final ids = _slots.keys.toList();
      if (ids.isEmpty) {
        final starterIds = widget.data.lineup
            .where((p) => p.isStarter)
            .map((p) => p.userId)
            .toList();
        if (starterIds.isNotEmpty) {
          _slots = defaultSlotsForFormation(f, starterIds);
        }
      } else {
        _slots = defaultSlotsForFormation(f, ids);
      }
    });
    if (notify) {
      widget.onMessage('Posiciones actualizadas para $f');
    }
  }

  void _addPlayerToField(int userId) {
    if (_penEnabled) return;
    final ids = [..._slots.keys.where((id) => id != userId), userId];
    final positioned = defaultSlotsForFormation(_formation, ids);
    _syncLineupUi(() {
      _slots[userId] = positioned[userId] ?? const Offset(0.5, 0.55);
    });
  }

  void _removeFromField(int userId) {
    _syncLineupUi(() => _slots.remove(userId));
  }

  void _applyTacticalBoard(TacticalBoard board) {
    _syncLineupUi(() {
      if (board.formation != null && board.formation!.isNotEmpty) {
        _formation = board.formation!;
      }
      _slots = Map.from(board.lineupSlots);
      _strokes = List.from(board.boardStrokes);
    });
    widget.onMessage('Táctica "${board.name}" aplicada');
  }

  void _onDropOnField(DragTargetDetails<int> details) {
    if (_penEnabled) return;
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.offset);
    final nx = (local.dx / box.size.width).clamp(0.05, 0.95);
    final ny = (local.dy / box.size.height).clamp(0.05, 0.95);
    _syncLineupUi(
      () => _slots[details.data] = Offset(nx, ny),
    );
  }

  Future<void> _saveAsTactic() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar táctica'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Presión alta vs 4-4-2',
          ),
          autofocus: true,
          maxLength: 120,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;

    try {
      await _tacticalService.create(
        widget.data.teamId,
        name: name,
        formation: _formation,
        lineupSlots: TacticalBoardService.slotsToPayload(_slots),
        boardStrokes: TacticalBoardService.strokesToPayload(_strokes),
      );
      widget.onMessage('Táctica "$name" guardada');
      await _loadSavedBoards();
    } catch (e) {
      widget.onMessage(TacticalBoardService.errorMessage(e), error: true);
    }
  }

  Future<void> _shareTactic(TacticalBoard board) async {
    try {
      final info = await _tacticalService.enableShare(
        widget.data.teamId,
        board.id,
      );
      final url = info.fullUrl(AppConfig.apiBaseUrl);
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enlace copiado'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      widget.onMessage(TacticalBoardService.errorMessage(e), error: true);
    }
  }

  Future<void> _deleteTactic(TacticalBoard board) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar táctica'),
        content: Text('¿Eliminar "${board.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _tacticalService.delete(widget.data.teamId, board.id);
      widget.onMessage('Táctica eliminada');
      await _loadSavedBoards();
    } catch (e) {
      widget.onMessage(TacticalBoardService.errorMessage(e), error: true);
    }
  }

  void _showTacticsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        maxChildSize: 0.85,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    'Tácticas guardadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Actualizar lista',
                    onPressed: _loadSavedBoards,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingBoards
                  ? const Center(child: CircularProgressIndicator())
                  : _savedBoards.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay tácticas guardadas.\n'
                              'Usá "Guardar táctica" para crear una.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          itemCount: _savedBoards.length,
                          itemBuilder: (_, i) {
                            final b = _savedBoards[i];
                            return ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: Text(b.name),
                              subtitle: Text(b.formation ?? 'Sin formación'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  Navigator.pop(ctx);
                                  switch (v) {
                                    case 'apply':
                                      _applyTacticalBoard(b);
                                      break;
                                    case 'share':
                                      _shareTactic(b);
                                      break;
                                    case 'delete':
                                      _deleteTactic(b);
                                      break;
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'apply',
                                    child: Text('Aplicar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Text('Compartir enlace'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _applyTacticalBoard(b);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 0,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Formación:'),
          ),
          DropdownButton<String>(
            value: _formations.contains(_formation) ? _formation : '4-4-2',
            items: _formations
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) {
              if (v != null) _applyFormation(v, notify: true);
            },
          ),
          _toolBtn(
            tooltip:
                'Aplicar posiciones automáticas de la formación seleccionada',
            icon: Icons.grid_on,
            onPressed: () => _applyFormation(_formation, notify: true),
          ),
          _toolBtn(
            tooltip: _penEnabled
                ? 'Salir del lápiz (mover jugadores)'
                : 'Lápiz: dibujar jugadas en la cancha',
            icon: _penEnabled ? Icons.pan_tool_alt : Icons.draw,
            color: _penEnabled ? Colors.amber.shade800 : null,
            onPressed: () => _syncLineupUi(() => _penEnabled = !_penEnabled),
          ),
          if (_penEnabled) ...[
            _toolBtn(
              tooltip: 'Deshacer último trazo',
              icon: Icons.undo,
              onPressed: _strokes.isEmpty
                  ? null
                  : () => _syncLineupUi(() => _strokes.removeLast()),
            ),
            _toolBtn(
              tooltip: 'Borrar todos los dibujos',
              icon: Icons.delete_outline,
              onPressed: _strokes.isEmpty
                  ? null
                  : () => _syncLineupUi(() => _strokes.clear()),
            ),
          ],
          _toolBtn(
            tooltip: 'Ver y aplicar tácticas guardadas',
            icon: Icons.folder_open,
            onPressed: _showTacticsSheet,
          ),
          _toolBtn(
            tooltip: 'Guardar alineación y dibujos con un nombre',
            icon: Icons.bookmark_add_outlined,
            onPressed: _saveAsTactic,
          ),
        ],
      ),
    );
  }

  Widget _fieldArea({required bool wide}) {
    final field = _penEnabled
        ? _fieldStack(readOnly: false, drawOnly: true)
        : DragTarget<int>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: _onDropOnField,
            builder: (context, candidate, rejected) {
              return Container(
                decoration: BoxDecoration(
                  border: candidate.isNotEmpty
                      ? Border.all(color: Colors.amber, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _fieldStack(readOnly: false, trackDrop: true),
              );
            },
          );

    return Padding(
      padding: EdgeInsets.all(wide ? 8 : 4),
      child: field,
    );
  }

  Widget _playerPool({required bool horizontal}) {
    final confirmed = _confirmed;
    final others =
        widget.data.lineup.where((p) => !p.confirmed).toList(growable: false);

    if (horizontal) {
      final chips = <Widget>[];
      void addGroup(String label, List<PostMatchLineupRow> players) {
        if (players.isEmpty) return;
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 2),
            child: Chip(
              label: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ),
        );
        for (final p in players) {
          chips.add(Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _playerChip(p, horizontal: true),
          ));
        }
      }

      addGroup('Confirmados (${confirmed.length})', confirmed);
      addGroup('Otros convocados (${others.length})', others);

      if (chips.isEmpty) {
        return Center(
          child: Text(
            'Sin jugadores convocados',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }

      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: chips,
      );
    }

    final sections = <Widget>[
      _poolSection(
        title: 'Confirmados (${confirmed.length})',
        players: confirmed,
        horizontal: horizontal,
      ),
      if (others.isNotEmpty)
        _poolSection(
          title: 'Otros convocados (${others.length})',
          players: others,
          horizontal: horizontal,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Text(
            'Tocá para agregar · arrastrá en la cancha para mover · X para quitar',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: sections,
          ),
        ),
      ],
    );
  }

  Widget _poolSection({
    required String title,
    required List<PostMatchLineupRow> players,
    required bool horizontal,
  }) {
    if (players.isEmpty) return const SizedBox.shrink();

    final chips = players.map((p) => _playerChip(p, horizontal: horizontal));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!horizontal)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
        if (horizontal)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        if (horizontal)
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: chips
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: c,
                      ))
                  .toList(),
            ),
          )
        else
          ...chips.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
              child: c,
            ),
          ),
      ],
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return name;
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  Widget _playerChip(PostMatchLineupRow p, {required bool horizontal}) {
    final onField = _slots.containsKey(p.userId);
    final canInteract = !_penEnabled;

    final chip = Material(
      color: onField ? Colors.green.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canInteract
            ? () {
                if (onField) {
                  _removeFromField(p.userId);
                } else {
                  _addPlayerToField(p.userId);
                }
              }
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? 8 : 10,
            vertical: horizontal ? 6 : 8,
          ),
          child: horizontal
              ? SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PlayerAvatar(
                            avatarUrl: p.avatarUrl,
                            displayName: p.userName,
                            radius: 16,
                            badgeText: p.jerseyNumber?.toString(),
                          ),
                          if (onField)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _shortName(p.userName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    PlayerAvatar(
                      avatarUrl: p.avatarUrl,
                      displayName: p.userName,
                      radius: 20,
                      badgeText: p.jerseyNumber?.toString(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            p.confirmed ? 'Confirmado' : 'Pendiente',
                            style: TextStyle(
                              fontSize: 11,
                              color: p.confirmed
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onField)
                      IconButton(
                        tooltip: 'Quitar de la cancha',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed:
                            canInteract ? () => _removeFromField(p.userId) : null,
                      )
                    else
                      IconButton(
                        tooltip: 'Agregar a la cancha',
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        onPressed:
                            canInteract ? () => _addPlayerToField(p.userId) : null,
                      ),
                  ],
                ),
        ),
      ),
    );

    if (_penEnabled || horizontal) return chip;

    return LongPressDraggable<int>(
      data: p.userId,
      feedback: Material(
        color: Colors.transparent,
        child: PlayerAvatar(
          avatarUrl: p.avatarUrl,
          displayName: p.userName,
          radius: 26,
          badgeText: p.jerseyNumber?.toString(),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
  }

  Future<void> _openFullscreenLineup() async {
    if (!mounted || _lineupModalOpen) return;
    setState(() => _lineupModalOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar alineación',
        pageBuilder: (ctx, _, __) {
          final h = MediaQuery.sizeOf(ctx).height;
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              _modalSetState = setModalState;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: h * 0.94,
                    width: double.infinity,
                    child: _LineupFullscreenSheet(
                      toolbar: _toolbar(),
                      penHint: _penEnabled
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Text(
                                'Modo lápiz activo. Desactivá el lápiz para mover jugadores.',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            )
                          : null,
                      field: _fieldArea(wide: false),
                      pool: _playerPool(horizontal: true),
                      saveBar: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () async {
                                    await _save();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Guardar y cerrar'),
                          ),
                        ),
                      ),
                      onClose: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _modalSetState = null;
      if (mounted) setState(() => _lineupModalOpen = false);
    }
  }

  Widget _mobileLineupPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: _lineupModalOpen
                      ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A27)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2D5A27)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen,
                                  size: 40,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Editando en pantalla completa…',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      : IgnorePointer(
                          child: _fieldStack(readOnly: true),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: FilledButton.tonalIcon(
                  onPressed: _lineupModalOpen ? null : _openFullscreenLineup,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(
                    'Abrir cancha (${_slots.length} en campo)',
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 96,
            child: _playerPool(horizontal: true),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.lineup.isEmpty) {
      return const Center(child: Text('Sin plantel convocado'));
    }

    if (!widget.data.canManage) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          AspectRatio(
            aspectRatio: 0.68,
            child: _fieldStack(readOnly: true),
          ),
        ],
      );
    }

    final wide = _isWide(context);

    return Column(
      children: [
        _toolbar(),
        if (_penEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Modo lápiz activo. Desactivá el lápiz para mover jugadores.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _fieldArea(wide: true)),
                    Expanded(flex: 2, child: _playerPool(horizontal: false)),
                  ],
                )
              : _mobileLineupPreview(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar alineación'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldStack({
    required bool readOnly,
    bool drawOnly = false,
    bool trackDrop = false,
  }) {
    return Stack(
      key: trackDrop ? _fieldKey : null,
      fit: StackFit.expand,
      children: [
        MatchFieldWidget(
          players: widget.data.lineup,
          slots: _slots,
          formation: _formation,
          compact: true,
          showFormationLabel: false,
          onPlayerTap: null,
          onSlotMoved: readOnly || _penEnabled
              ? null
              : (userId, offset) {
                  _syncLineupUi(() => _slots[userId] = offset);
                },
        ),
        FieldDrawingOverlay(
          strokes: _strokes,
          drawEnabled: !readOnly && (_penEnabled || drawOnly),
          onStrokesChanged: (s) => _syncLineupUi(() => _strokes = s),
        ),
      ],
    );
  }
}

class _LineupFullscreenSheet extends StatelessWidget {
  final Widget toolbar;
  final Widget? penHint;
  final Widget field;
  final Widget pool;
  final Widget saveBar;
  final VoidCallback onClose;

  const _LineupFullscreenSheet({
    required this.toolbar,
    this.penHint,
    required this.field,
    required this.pool,
    required this.saveBar,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  'Alineación — pantalla completa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        toolbar,
        if (penHint != null) penHint!,
        Expanded(child: field),
        Material(
          elevation: 8,
          child: SizedBox(height: 104, child: pool),
        ),
        saveBar,
      ],
    );
  }
}
