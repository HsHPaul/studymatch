class StudySession {
  final String id;
  final String matchId;
  final String datum;
  final String uhrzeit;
  final String? uhrzeitEnde;
  final String status;
  final String? raumId;
  final String partnerAlias;
  final String? createdById;
  final String? proposedDatum;
  final String? proposedUhrzeit;
  final String? proposedUhrzeitEnde;
  final String? proposedRaumId;
  final String? editProposedById;
  final bool iProposedEdit;

  const StudySession({
    required this.id,
    required this.matchId,
    required this.datum,
    required this.uhrzeit,
    this.uhrzeitEnde,
    required this.status,
    required this.partnerAlias,
    this.raumId,
    this.createdById,
    this.proposedDatum,
    this.proposedUhrzeit,
    this.proposedUhrzeitEnde,
    this.proposedRaumId,
    this.editProposedById,
    this.iProposedEdit = false,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        datum: json['datum'] as String,
        uhrzeit: json['uhrzeit'] as String,
        uhrzeitEnde: json['uhrzeit_ende'] as String?,
        status: json['status'] as String,
        raumId: json['raum_id'] as String?,
        partnerAlias: json['partner_alias'] as String? ?? 'Unbekannt',
        createdById: json['created_by_id'] as String?,
        proposedDatum: json['proposed_datum'] as String?,
        proposedUhrzeit: json['proposed_uhrzeit'] as String?,
        proposedUhrzeitEnde: json['proposed_uhrzeit_ende'] as String?,
        proposedRaumId: json['proposed_raum_id'] as String?,
        editProposedById: json['edit_proposed_by_id'] as String?,
        iProposedEdit: json['i_proposed_edit'] as bool? ?? false,
      );

  bool get hasPendingEdit => editProposedById != null;
  bool get isRequested => status == 'angefragt';

  DateTime get dateTime {
    final time = uhrzeit.length > 5 ? uhrzeit.substring(0, 5) : uhrzeit;
    return DateTime.parse('${datum}T$time:00');
  }

  bool get isUpcoming => dateTime.isAfter(DateTime.now());
}
