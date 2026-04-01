import '../../domain/entities/user.dart';

/// Modelo de datos que mapea la respuesta JSON del backend a la entidad [User].
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.username,
    required super.email,
    required super.role,
    super.avatarUrl,
    super.canAccessAiModule,
    super.canAccessStatsModule,
    super.canViewStudentStats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:                   (json['id'] as num).toInt(),
      name:                  json['name']                          as String,
      username:              json['username']                      as String?,
      email:                 json['email']                         as String,
      role:                  json['role']                          as String,
      avatarUrl:             json['avatar_url']                    as String?,
      canAccessAiModule:    (json['can_access_ai_module']    as bool?) ?? false,
      canAccessStatsModule: (json['can_access_stats_module'] as bool?) ?? false,
      canViewStudentStats:  (json['can_view_student_stats']  as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':                     id,
      'name':                   name,
      'username':               username,
      'email':                  email,
      'role':                   role,
      'avatar_url':             avatarUrl,
      'can_access_ai_module':   canAccessAiModule,
      'can_access_stats_module': canAccessStatsModule,
      'can_view_student_stats': canViewStudentStats,
    };
  }

  /// Convierte la entidad base en un [UserModel] (útil para persistir).
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id:                   user.id,
      name:                 user.name,
      username:             user.username,
      email:                user.email,
      role:                 user.role,
      avatarUrl:            user.avatarUrl,
      canAccessAiModule:    user.canAccessAiModule,
      canAccessStatsModule: user.canAccessStatsModule,
      canViewStudentStats:  user.canViewStudentStats,
    );
  }
}
