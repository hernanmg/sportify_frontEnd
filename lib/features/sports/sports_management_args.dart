/// Argumentos de navegación hacia [SportsManagementScreen].
class SportsManagementArgs {
  /// Índice de pestaña: 0 plantel, 1 eventos, 2 convocatorias, 3 estado jugadores.
  final int initialTabIndex;
  final int? initialTeamId;

  const SportsManagementArgs({
    this.initialTabIndex = 0,
    this.initialTeamId,
  });

  /// Abre la pestaña "Estado Jugadores" (lesiones, apto, cuotas).
  factory SportsManagementArgs.playerStatus({int? teamId}) {
    return SportsManagementArgs(initialTabIndex: 3, initialTeamId: teamId);
  }
}
