class StudySession {
  final String id;
  final String matchId;
  final String datum;
  final String uhrzeit;
  final String status;
  final String? raumId;

  const StudySession({
    required this.id,
    required this.matchId,
    required this.datum,
    required this.uhrzeit,
    required this.status,
    this.raumId,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        datum: json['datum'] as String,
        uhrzeit: json['uhrzeit'] as String,
        status: json['status'] as String,
        raumId: json['raum_id'] as String?,
      );

  DateTime get dateTime {
    final time = uhrzeit.length > 5 ? uhrzeit.substring(0, 5) : uhrzeit;
    return DateTime.parse('${datum}T$time:00');
  }

  bool get isUpcoming => dateTime.isAfter(DateTime.now());
}
