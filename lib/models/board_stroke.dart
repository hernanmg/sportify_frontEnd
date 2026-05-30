import 'dart:ui' show Offset;

class BoardStroke {
  final List<Offset> points;
  final String color;
  final double width;

  const BoardStroke({
    required this.points,
    this.color = '#FFFFFF',
    this.width = 2.5,
  });

  Map<String, dynamic> toJson() => {
        'points': points
            .map((p) => {'x': p.dx.clamp(0.0, 1.0), 'y': p.dy.clamp(0.0, 1.0)})
            .toList(),
        'color': color,
        'width': width,
      };

  factory BoardStroke.fromJson(Map<String, dynamic> json) {
    final pts = <Offset>[];
    for (final p in json['points'] as List<dynamic>? ?? []) {
      if (p is! Map) continue;
      final x = (p['x'] as num?)?.toDouble();
      final y = (p['y'] as num?)?.toDouble();
      if (x != null && y != null) {
        pts.add(Offset(x, y));
      }
    }
    return BoardStroke(
      points: pts,
      color: json['color']?.toString() ?? '#FFFFFF',
      width: (json['width'] as num?)?.toDouble() ?? 2.5,
    );
  }

  static List<BoardStroke> listFromJson(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => BoardStroke.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
