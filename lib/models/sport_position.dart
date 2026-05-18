class SportPosition {
  final int id;
  final int sportId;
  final String code;
  final String label;
  final int sortOrder;

  SportPosition({
    required this.id,
    required this.sportId,
    required this.code,
    required this.label,
    this.sortOrder = 0,
  });

  factory SportPosition.fromJson(Map<String, dynamic> json) {
    return SportPosition(
      id: json['id'] as int,
      sportId: json['sportId'] ?? json['sport_id'] ?? 0,
      code: json['code'] as String,
      label: json['label'] as String,
      sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
    );
  }
}
