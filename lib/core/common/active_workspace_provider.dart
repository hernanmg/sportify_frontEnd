import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/workspace/workspace_pick_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team.dart';

/// Equipo (y categoría opcional) activos para toda la sesión de trabajo.
class ActiveWorkspaceProvider extends ChangeNotifier {
  final TeamService _teamService = TeamService();
  final AuthStorageService _authStorage = AuthStorageService();

  List<MyTeamOption> _teamOptions = [];
  Team? _team;
  int? _categoryId;
  bool _loading = false;
  bool _ready = false;

  Team? get team => _team;
  int? get teamId => _team?.id;
  int? get categoryId => _categoryId;
  List<MyTeamOption> get teamOptions => List.unmodifiable(_teamOptions);
  bool get ready => _ready;
  bool get hasTeam => _team != null;

  bool get hasMultipleCategories =>
      (_team?.categoryIds.length ?? 0) > 1;

  List<({int id, String name})> get categories {
    final t = _team;
    if (t == null) return [];
    final ids = t.categoryIds;
    final names = t.categoryNames;
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

  String _teamKey(String userId) => 'active_workspace_team_$userId';
  String _categoryKey(String userId) => 'active_workspace_category_$userId';

  Future<void> load({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    try {
      final role = await _authStorage.getRole();
      final isPlatformAdmin = UserCapabilities.isPlatformAdmin(role);

      var options =
          MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (options.isEmpty && isPlatformAdmin) {
        final all = await _teamService.getAllTeams();
        options = all
            .map(
              (t) => MyTeamOption(
                teamId: t.id,
                name: t.name,
                categories: t.categoryNames,
                categoryIds: t.categoryIds,
                team: t,
              ),
            )
            .toList();
      }

      _teamOptions = options;

      final userId = await _authStorage.getUserId();
      Team? resolved;
      int? resolvedCategory;

      if (userId != null && options.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedTeamId = prefs.getInt(_teamKey(userId));
        final savedCategoryId = prefs.getInt(_categoryKey(userId));

        if (savedTeamId != null) {
          final opt = MyTeamOption.findInList(options, savedTeamId);
          resolved = opt?.team;
        }
        resolved ??= options.length == 1 ? options.first.team : null;

        if (resolved != null &&
            savedCategoryId != null &&
            resolved.categoryIds.contains(savedCategoryId)) {
          resolvedCategory = savedCategoryId;
        } else if (resolved != null && resolved.categoryIds.length == 1) {
          resolvedCategory = resolved.categoryIds.first;
        }
      }

      _team = resolved;
      _categoryId = resolvedCategory;
      _ready = true;
      notifyListeners();
    } catch (_) {
      _ready = true;
      notifyListeners();
    } finally {
      _loading = false;
    }
  }

  Future<bool> ensureResolved(BuildContext context) async {
    await load(force: true);
    if (_teamOptions.isEmpty) return true;
    if (_team != null) return true;
    if (_teamOptions.length == 1) {
      await selectTeam(_teamOptions.first);
      return true;
    }
    if (!context.mounted) return false;
    final picked = await Navigator.of(context).push<MyTeamOption>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkspacePickScreen(options: _teamOptions),
      ),
    );
    if (picked == null) return false;
    await selectTeam(picked);
    return true;
  }

  Future<void> selectTeam(MyTeamOption option, {int? categoryId}) async {
    _team = option.team;
    final explicit = categoryId ??
        (option.categoryIds.length == 1 ? option.categoryIds.first : null);
    if (explicit != null && option.team.categoryIds.contains(explicit)) {
      _categoryId = explicit;
    } else if (option.team.categoryIds.length == 1) {
      _categoryId = option.team.categoryIds.first;
    } else {
      _categoryId = null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setCategoryId(int? categoryId) async {
    if (categoryId != null &&
        !(_team?.categoryIds.contains(categoryId) ?? false)) {
      return;
    }
    _categoryId = categoryId;
    await _persist();
    notifyListeners();
  }

  Future<void> openTeamPicker(BuildContext context) async {
    await load(force: true);
    if (_teamOptions.isEmpty || !context.mounted) return;
    final picked = await Navigator.of(context).push<MyTeamOption>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkspacePickScreen(
          options: _teamOptions,
          initialTeamId: _team?.id,
          initialCategoryId: _categoryId,
        ),
      ),
    );
    if (picked != null) {
      await selectTeam(
        picked,
        categoryId:
            picked.categoryIds.length == 1 ? picked.categoryIds.first : null,
      );
    }
  }

  Future<void> _persist() async {
    final userId = await _authStorage.getUserId();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final tid = _team?.id;
    if (tid != null) {
      await prefs.setInt(_teamKey(userId), tid);
    } else {
      await prefs.remove(_teamKey(userId));
    }
    final cid = _categoryId;
    if (cid != null) {
      await prefs.setInt(_categoryKey(userId), cid);
    } else {
      await prefs.remove(_categoryKey(userId));
    }
  }

  Future<void> clear() async {
    final userId = await _authStorage.getUserId();
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_teamKey(userId));
      await prefs.remove(_categoryKey(userId));
    }
    _team = null;
    _categoryId = null;
    _teamOptions = [];
    _ready = false;
    notifyListeners();
  }
}
