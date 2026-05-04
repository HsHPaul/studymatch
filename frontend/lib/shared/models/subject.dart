class Subject {
  final String id;
  final String name;
  final String? kuerzel;

  const Subject({required this.id, required this.name, this.kuerzel});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        kuerzel: json['kuerzel'] as String?,
      );

  String get displayName => kuerzel != null ? '$name ($kuerzel)' : name;

  @override
  bool operator ==(Object other) => other is Subject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
