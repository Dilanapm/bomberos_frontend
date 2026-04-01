/// Entidad de dominio que representa al usuario autenticado.
/// Sin dependencias de frameworks externos.
class User {
  const User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.canAccessAiModule = false,
    this.canAccessStatsModule = false,
    this.canViewStudentStats = false,
  });

  final int id;
  final String name;
  final String? username;
  final String email;

  /// 'instructor' | 'aprendiz'
  final String role;
  final String? avatarUrl;

  /// Permiso para acceder al módulo de IA.
  final bool canAccessAiModule;

  /// Permiso del aprendiz para ver sus propias estadísticas.
  final bool canAccessStatsModule;

  /// Permiso para ver estadísticas de estudiantes.
  final bool canViewStudentStats;

  bool get isInstructor => role == 'instructor';
  bool get isAprendiz   => role == 'aprendiz';

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? role,
    String? avatarUrl,
    bool? canAccessAiModule,
    bool? canAccessStatsModule,
    bool? canViewStudentStats,
  }) {
    return User(
      id:                   id                   ?? this.id,
      name:                 name                 ?? this.name,
      username:             username             ?? this.username,
      email:                email                ?? this.email,
      role:                 role                 ?? this.role,
      avatarUrl:            avatarUrl            ?? this.avatarUrl,
      canAccessAiModule:    canAccessAiModule    ?? this.canAccessAiModule,
      canAccessStatsModule: canAccessStatsModule ?? this.canAccessStatsModule,
      canViewStudentStats:  canViewStudentStats  ?? this.canViewStudentStats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
