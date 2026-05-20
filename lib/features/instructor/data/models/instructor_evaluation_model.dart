import '../../domain/entities/instructor_evaluation.dart';

class InstructorEvaluationModel extends InstructorEvaluation {
  const InstructorEvaluationModel({
    required super.id,
    required super.aprendizName,
    required super.aprendizUsername,
    required super.generalScore,
    required super.status,
    required super.createdAt,
    super.aprendizAvatar,
    super.commentsCount,
    super.reviewed,
    super.scoreFinal,
  });

  factory InstructorEvaluationModel.fromJson(Map<String, dynamic> json) {
    final aprendiz = json['aprendiz'] as Map<String, dynamic>? ?? {};
    return InstructorEvaluationModel(
      id:               (json['id'] as num).toInt(),
      aprendizName:     aprendiz['name'] as String? ?? '',
      aprendizUsername: aprendiz['username'] as String? ?? '',
      aprendizAvatar:   aprendiz['avatar'] as String?,
      generalScore:     (json['general_score'] as num?)?.toDouble() ?? 0.0,
      status:           json['status'] as String? ?? '',
      createdAt:        DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      commentsCount:    (json['comments_count'] as num?)?.toInt() ?? 0,
      reviewed:         json['reviewed'] as bool? ?? false,
      scoreFinal:       (json['score_final'] as num?)?.toDouble(),
    );
  }
}
