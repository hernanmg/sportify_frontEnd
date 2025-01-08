enum AttendanceStatus { attending, maybe, notAttending }
enum EventType { training, game, strength, testing, recover }
enum ParticipationType { full, partial, limited, out }

class Event {
  final String id;
  final String gameId;
  final EventType type;
  final String jugador;
  final int minuto;
  final String location;
  final DateTime startTime;
  final int durationMinutes;
  final String fieldNumber;
  final bool isRequired;
  final int earlyArrivalMinutes;
  final List<String> requiredKit;
  final bool notifyPlayers;
  final Map<String, AttendanceStatus> attendance;
  final Map<String, String> absenceReasons;
  final bool isMandatory;
  final String teamId;
  Event({
    required this.id,
    required this.gameId,
    required this.type,
    required this.jugador,
    required this.minuto,
    required this.location,
    required this.startTime,
    required this.durationMinutes,
    required this.fieldNumber,
    this.isRequired = false,
    this.earlyArrivalMinutes = 0,
    this.requiredKit = const [],
    this.notifyPlayers = true,
    this.attendance = const {},
    this.absenceReasons = const {},
    this.isMandatory = false,
    required this.teamId,
  });
}
