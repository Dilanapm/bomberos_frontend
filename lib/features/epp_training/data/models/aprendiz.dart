/// Aprendiz devuelto por `GET /instructor/aprendices/all`.
class Aprendiz {
  const Aprendiz({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? avatarUrl;

  factory Aprendiz.fromJson(Map<String, dynamic> json) => Aprendiz(
        id:        json['id']         as int,
        name:      json['name']       as String,
        username:  json['username']   as String?,
        email:     json['email']      as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  String get displayName => name;
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
