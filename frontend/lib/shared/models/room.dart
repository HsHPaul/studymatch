class Room {
  final String id;
  final String name;
  final String? gebaeude;
  final int kapazitaet;

  const Room({
    required this.id,
    required this.name,
    this.gebaeude,
    required this.kapazitaet,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        name: json['name'] as String,
        gebaeude: json['gebaeude'] as String?,
        kapazitaet: json['kapazitaet'] as int,
      );

  String get displayName =>
      gebaeude != null ? '$name · $gebaeude' : name;
}
