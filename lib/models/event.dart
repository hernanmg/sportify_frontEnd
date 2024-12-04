class Event {
  final String id;
  final String gameId;
  final String tipoEvento;
  final String jugador;
  final int minuto;

  Event({
    required this.id,
    required this.gameId,
    required this.tipoEvento,
    required this.jugador,
    required this.minuto,
  });
}
