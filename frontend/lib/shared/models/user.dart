class UserProfile {
  final String id;
  final String alias;
  final String email;
  final String? studiengang;
  final String? lernstil;
  final String? bio;
  final double minMatchScore;

  const UserProfile({
    required this.id,
    required this.alias,
    required this.email,
    this.studiengang,
    this.lernstil,
    this.bio,
    this.minMatchScore = 0.0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        alias: json['alias'] as String,
        email: json['email'] as String,
        studiengang: json['studiengang'] as String?,
        lernstil: json['lernstil'] as String?,
        bio: json['bio'] as String?,
        minMatchScore: (json['min_match_score'] as num?)?.toDouble() ?? 0.0,
      );

  int get minMatchPercent => (minMatchScore * 100).round();
}
