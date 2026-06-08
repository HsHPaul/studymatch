class AvailabilityOverlap {
  final String wochentag;
  final String startTime;
  final String endTime;

  const AvailabilityOverlap({
    required this.wochentag,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilityOverlap.fromJson(Map<String, dynamic> json) =>
      AvailabilityOverlap(
        wochentag: json['wochentag'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
      );

  String get timeRange =>
      '${startTime.substring(0, 5)}–${endTime.substring(0, 5)}';
}

class Match {
  final String matchId;
  final String userId;
  final String alias;
  final String? studiengang;
  final String? lernstil;
  final List<String> gemeinsacheFaecher;
  final List<AvailabilityOverlap> ueberschneidungen;
  final double score;
  final String status;
  final bool iRequested;

  const Match({
    required this.matchId,
    required this.userId,
    required this.alias,
    this.studiengang,
    this.lernstil,
    required this.gemeinsacheFaecher,
    required this.ueberschneidungen,
    required this.score,
    required this.status,
    required this.iRequested,
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        matchId: json['match_id'] as String,
        userId: json['user_id'] as String,
        alias: json['alias'] as String,
        studiengang: json['studiengang'] as String?,
        lernstil: json['lernstil'] as String?,
        gemeinsacheFaecher:
            (json['gemeinsame_faecher'] as List).cast<String>(),
        ueberschneidungen: (json['ueberschneidungen'] as List)
            .map((e) =>
                AvailabilityOverlap.fromJson(e as Map<String, dynamic>))
            .toList(),
        score: (json['score'] as num).toDouble(),
        status: json['status'] as String? ?? 'vorgeschlagen',
        iRequested: json['i_requested'] as bool? ?? false,
      );

  int get scorePercent => (score * 100).round();
  bool get isAccepted => status == 'akzeptiert';
  bool get isPending => status == 'angefragt';
  bool get isSuggestion => status == 'vorgeschlagen';
}
