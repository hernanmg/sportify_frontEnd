class ConvocationTemplate {
  final int id;
  final int teamId;
  final String name;
  final List<int> defaultParticipantUserIds;
  final Map<String, dynamic>? metadata;

  ConvocationTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    this.defaultParticipantUserIds = const [],
    this.metadata,
  });

  factory ConvocationTemplate.fromJson(Map<String, dynamic> json) {
    final ids = json['defaultParticipantUserIds'] ??
        json['default_participant_user_ids'];
    return ConvocationTemplate(
      id: json['id'] as int,
      teamId: json['teamId'] ?? json['team_id'],
      name: json['name'] as String,
      defaultParticipantUserIds: ids is List
          ? ids.map((e) => int.parse('$e')).toList()
          : [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'defaultParticipantUserIds': defaultParticipantUserIds,
        if (metadata != null) 'metadata': metadata,
      };
}
