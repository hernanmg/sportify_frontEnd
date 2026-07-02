import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

/// Elige equipo activo (y categoría si aplica) al iniciar sesión o desde ajustes.
class WorkspacePickScreen extends StatefulWidget {
  final List<MyTeamOption> options;
  final int? initialTeamId;
  final int? initialCategoryId;

  const WorkspacePickScreen({
    super.key,
    required this.options,
    this.initialTeamId,
    this.initialCategoryId,
  });

  @override
  State<WorkspacePickScreen> createState() => _WorkspacePickScreenState();
}

class _WorkspacePickScreenState extends State<WorkspacePickScreen> {
  MyTeamOption? _selected;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeamId != null) {
      _selected = MyTeamOption.findInList(widget.options, widget.initialTeamId!);
    }
    _selected ??= widget.options.isNotEmpty ? widget.options.first : null;
    _categoryId = widget.initialCategoryId;
    _syncDefaultCategory();
  }

  void _syncDefaultCategory() {
    final team = _selected?.team;
    if (team == null) return;
    if (_categoryId != null && team.categoryIds.contains(_categoryId)) {
      return;
    }
    if (team.categoryIds.length == 1) {
      _categoryId = team.categoryIds.first;
    } else {
      _categoryId = null;
    }
  }

  List<({int id, String name})> _categoriesFor(MyTeamOption? opt) {
    if (opt == null) return [];
    final ids = opt.team.categoryIds;
    final names = opt.categories;
    if (ids.isEmpty) return [];
    return List.generate(
      ids.length,
      (i) => (
        id: ids[i],
        name: i < names.length && names[i].trim().isNotEmpty
            ? names[i]
            : 'Categoría ${ids[i]}',
      ),
    );
  }

  void _confirm() {
    final opt = _selected;
    if (opt == null) return;
    final cats = _categoriesFor(opt);
    if (cats.length > 1 && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná una categoría')),
      );
      return;
    }
    final result = cats.length <= 1
        ? opt
        : MyTeamOption(
            teamId: opt.teamId,
            name: opt.name,
            categories: [
              cats.firstWhere((c) => c.id == _categoryId).name,
            ],
            categoryIds: [_categoryId!],
            isTeamAdmin: opt.isTeamAdmin,
            teamMemberRole: opt.teamMemberRole,
            canManageFinance: opt.canManageFinance,
            team: opt.team,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categoriesFor(_selected);
  final canDismiss = widget.options.length > 1 &&
        Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Con qué equipo trabajás?'),
        automaticallyImplyLeading: canDismiss,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tu equipo activo se usa en Gestión deportiva, finanzas y convocatorias.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...widget.options.map((opt) {
            final selected = _selected?.teamId == opt.teamId;
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  Icons.groups,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(opt.name),
                subtitle: opt.categories.isNotEmpty
                    ? Text(opt.categories.join(', '))
                    : null,
                trailing: selected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selected = opt;
                    _syncDefaultCategory();
                  });
                },
              ),
            );
          }),
          if (cats.length > 1) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: cats
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selected == null ? null : _confirm,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
