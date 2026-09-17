/// Permisos de UI según rol global del usuario.
///
/// Matriz operativa (piloto):
/// - **DT / admin plataforma**: deporte + finanzas + settings.
/// - **team_captain**: deporte (plantel/convocatorias); sin caja completa.
/// - **tesorero / delegado**: finanzas (cuotas, caja, movimientos, informes);
///   sin gestión deportiva ni edición de club.
/// - **player / guest**: cuenta propia y confirmaciones.
class UserCapabilities {
  static bool isPlatformAdmin(String? role) =>
      role == 'super_admin' || role == 'manager' || role == 'admin';

  /// Cuerpo técnico deportivo (no incluye tesorero/delegado).
  static bool isStaff(String? role) =>
      isPlatformAdmin(role) || role == 'dt' || role == 'team_captain';

  /// Roles de tesorería / administración financiera.
  static bool isFinanceRole(String? role) =>
      role == 'tesorero' || role == 'delegado';

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
  /// No incluye team_captain (usa canManageConvocationsOnly).
  static bool canManageTeamFinance(String? role) =>
      isPlatformAdmin(role) || role == 'dt' || isFinanceRole(role);

  /// Informes del equipo (asistencia + finanzas split).
  static bool canAccessTeamReports(String? role) =>
      canManageTeamFinance(role) || isStaff(role);

  /// Panel operativo DT (morosos, confirmaciones).
  static bool canAccessTeamAdminPanel(String? role) =>
      isStaff(role) || isFinanceRole(role);

  /// Solo convocatorias y deporte (sin panel financiero completo).
  static bool canManageConvocationsOnly(String? role) =>
      role == 'team_captain';
}
