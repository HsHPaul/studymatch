class UserProfile {
  final String id;
  final String alias;
  final String email;
  final String? studiengang;
  final String? lernstil;
  final String? bio;

  const UserProfile({
    required this.id,
    required this.alias,
    required this.email,
    this.studiengang,
    this.lernstil,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        alias: json['alias'] as String,
        email: json['email'] as String,
        studiengang: json['studiengang'] as String?,
        lernstil: json['lernstil'] as String?,
        bio: json['bio'] as String?,
      );

  UserProfile copyWith({
    String? alias,
    String? studiengang,
    String? lernstil,
    String? bio,
    bool clearLernstil = false,
    bool clearStudiengang = false,
    bool clearBio = false,
  }) =>
      UserProfile(
        id: id,
        alias: alias ?? this.alias,
        email: email,
        studiengang: clearStudiengang ? null : (studiengang ?? this.studiengang),
        lernstil: clearLernstil ? null : (lernstil ?? this.lernstil),
        bio: clearBio ? null : (bio ?? this.bio),
      );
}
