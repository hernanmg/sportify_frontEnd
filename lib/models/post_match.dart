class PostMatchPlayerOfMatch {
  final int userId;
  final String userName;
  final int? jerseyNumber;
  final double? officialScore;
  final double? teamAvgScore;

  PostMatchPlayerOfMatch({
    required this.userId,
    required this.userName,
    this.jerseyNumber,
    this.officialScore,
    this.teamAvgScore,
  });

  factory PostMatchPlayerOfMatch.fromJson(Map<String, dynamic> json) {
    return PostMatchPlayerOfMatch(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      jerseyNumber: json['jerseyNumber'] as int?,
      officialScore: _toDouble(json['officialScore']),
      teamAvgScore: _toDouble(json['teamAvgScore']),
    );
  }

  double? get displayScore => officialScore ?? teamAvgScore;
}

class PostMatchPlayerRow {
  final int userId;
  final String userName;
  final int? jerseyNumber;
  final bool isConvoked;
  final bool? attended;
  final double? teamAvgScore;
  final int teamVoteCount;
  final double? officialScore;
  final int? myVote;

  PostMatchPlayerRow({
    required this.userId,
    required this.userName,
    this.jerseyNumber,
    required this.isConvoked,
    this.attended,
    this.teamAvgScore,
    required this.teamVoteCount,
    this.officialScore,
    this.myVote,
  });

  factory PostMatchPlayerRow.fromJson(Map<String, dynamic> json) {
    return PostMatchPlayerRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      jerseyNumber: json['jerseyNumber'] as int?,
      isConvoked: json['isConvoked'] as bool? ?? true,
      attended: json['attended'] as bool?,
      teamAvgScore: _toDouble(json['teamAvgScore']),
      teamVoteCount: json['teamVoteCount'] as int? ?? 0,
      officialScore: _toDouble(json['officialScore']),
      myVote: json['myVote'] as int?,
    );
  }
}

class PostMatchData {
  final int eventId;
  final String title;
  final int teamId;
  final DateTime eventDate;
  final String status;
  final String? opponentName;
  final bool postMatchOpen;
  final bool votingClosed;
  final bool canVote;
  final bool canManage;
  final PostMatchPlayerOfMatch? playerOfMatch;
  final List<PostMatchPlayerRow> targets;
  final int myVotesCount;
  final int votesExpected;

  PostMatchData({
    required this.eventId,
    required this.title,
    required this.teamId,
    required this.eventDate,
    required this.status,
    this.opponentName,
    required this.postMatchOpen,
    required this.votingClosed,
    required this.canVote,
    required this.canManage,
    this.playerOfMatch,
    required this.targets,
    required this.myVotesCount,
    required this.votesExpected,
  });

  factory PostMatchData.fromJson(Map<String, dynamic> json) {
    final pom = json['playerOfMatch'];
    return PostMatchData(
      eventId: json['eventId'] as int,
      title: json['title']?.toString() ?? 'Partido',
      teamId: json['teamId'] as int,
      eventDate: DateTime.parse(json['eventDate'] as String),
      status: json['status']?.toString() ?? '',
      opponentName: json['opponentName']?.toString(),
      postMatchOpen: json['postMatchOpen'] as bool? ?? false,
      votingClosed: json['votingClosed'] as bool? ?? false,
      canVote: json['canVote'] as bool? ?? false,
      canManage: json['canManage'] as bool? ?? false,
      playerOfMatch: pom is Map<String, dynamic>
          ? PostMatchPlayerOfMatch.fromJson(pom)
          : null,
      targets: (json['targets'] as List<dynamic>? ?? [])
          .map((e) => PostMatchPlayerRow.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      myVotesCount: json['myVotesCount'] as int? ?? 0,
      votesExpected: json['votesExpected'] as int? ?? 0,
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
