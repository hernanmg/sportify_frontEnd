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

  /// Entrenamientos, partidos y gestión de eventos del equipo.
  static bool canManageSportsEvents(String? role) => isStaff(role);

  /// Generar códigos de invitación al plantel (DT / staff).
  static bool canInviteToTeam(String? role) => isStaff(role);

  /// Jugador: solo eventos sociales; staff gestiona el resto.
  static bool canOnlyCreateSocialEvents(String? role) =>
      !canManageSportsEvents(role);

  /// Sumar jugadores a convocatorias ya enviadas (solo DT y admin de plataforma).
  static bool canAddToSentConvocation(String? role) =>
      isPlatformAdmin(role) || role == 'dt';

  /// Editar datos del club (nombre, logo, categorías).
  static bool canManageTeamSettings(String? role) =>
      isPlatformAdmin(role) || role == 'dt';

  /// Finanzas del equipo (cuotas, caja, gastos de entreno).
  static bool canManageTeamFinance(String? role) =>
      isPlatformAdmin(role) ||
      role == 'dt' ||
      role == 'tesorero' ||
      role == 'delegado';

  /// Solo convocatorias y deporte (sin panel financiero completo).
  static bool canManageConvocationsOnly(String? role) =>
      role == 'team_captain';
}
