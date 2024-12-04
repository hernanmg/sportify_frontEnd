class Game {
  final String id;
  final String equipoLocal;
  final String equipoVisitante;
  final String fecha;
  final String hora;

  Game({
    required this.id,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.fecha,
    required this.hora,
  });

    factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      equipoLocal: json['equipoLocal'],
      equipoVisitante: json['equipoVisitante'],
      fecha: json['fecha'],
      hora: json['hora'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipoLocal': equipoLocal,
      'equipoVisitante': equipoVisitante,
      'fecha': fecha,
      'hora': hora,
    };
  }
}
