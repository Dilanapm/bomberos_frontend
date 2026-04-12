import '../../domain/entities/instructor_comment.dart';

class InstructorCommentModel extends InstructorComment {
  const InstructorCommentModel({
    required super.id,
    required super.evaluationId,
    required super.instructorId,
    required super.comment,
    required super.type,
    required super.createdAt,
    super.stepNumber,
    super.instructorName,
    super.instructorAvatar,
  });

  factory InstructorCommentModel.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'] as Map<String, dynamic>? ?? {};
    return InstructorCommentModel(
      id:              (json['id'] as num).toInt(),
      evaluationId:    (json['evaluation_id'] as num).toInt(),
      instructorId:    (json['instructor_id'] as num).toInt(),
      comment:         json['comment'] as String? ?? '',
      type:            json['type'] as String? ?? 'observacion',
      stepNumber:      json['step_number'] != null
                           ? (json['step_number'] as num).toInt()
                           : null,
      createdAt:       DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      instructorName:  instructor['name'] as String? ?? '',
      instructorAvatar: instructor['avatar'] as String?,
    );
  }
}
