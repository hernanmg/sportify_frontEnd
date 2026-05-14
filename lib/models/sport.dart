class Sport {
  final int id;
  final String name;
  final DateTime? createdAt;

  Sport({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Sport && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
