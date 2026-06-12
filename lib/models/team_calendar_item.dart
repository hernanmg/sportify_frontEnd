enum TeamCalendarItemKind { event, birthday }

class TeamCalendarItem {
  final TeamCalendarItemKind kind;
  final String id;
  final DateTime date;
  final String title;
  final String? subtitle;
  final String? dayMonthLabel;
  final int? sportEventId;
  final String? eventType;
  final String? location;
  final int? userId;
  final String? userName;

  TeamCalendarItem({
    required this.kind,
    required this.id,
    required this.date,
    required this.title,
    this.subtitle,
    this.dayMonthLabel,
    this.sportEventId,
    this.eventType,
    this.location,
    this.userId,
    this.userName,
  });

  factory TeamCalendarItem.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind']?.toString() ?? 'event';
    return TeamCalendarItem(
      kind: kindRaw == 'birthday'
          ? TeamCalendarItemKind.birthday
          : TeamCalendarItemKind.event,
      id: json['id']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()).toLocal(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      dayMonthLabel: json['dayMonthLabel']?.toString(),
      sportEventId: json['sportEventId'] as int?,
      eventType: json['eventType']?.toString(),
      location: json['location']?.toString(),
      userId: json['userId'] as int?,
      userName: json['userName']?.toString(),
    );
  }
}

class TeamCalendarResponse {
  final int teamId;
  final String teamName;
  final List<TeamCalendarItem> items;

  TeamCalendarResponse({
    required this.teamId,
    required this.teamName,
    required this.items,
  });

  factory TeamCalendarResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return TeamCalendarResponse(
      teamId: json['teamId'] as int? ?? 0,
      teamName: json['teamName']?.toString() ?? '',
      items: list
          .map((e) => TeamCalendarItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
