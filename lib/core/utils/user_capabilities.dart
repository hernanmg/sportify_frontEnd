/// Permisos de UI según rol global del usuario.
class UserCapabilities {
  static bool isPlatformAdmin(String? role) =>
      role == 'super_admin' || role == 'manager' || role == 'admin';

  static bool isStaff(String? role) =>
      isPlatformAdmin(role) || role == 'dt' || role == 'team_captain';

  static bool isPlayer(String? role) =>
      role == 'player' || role == 'guest' || role == null || role.isEmpty;

  static bool canManageRoster(String? role) => isStaff(role);

  static bool canManageConvocations(String? role) => isStaff(role);
}
