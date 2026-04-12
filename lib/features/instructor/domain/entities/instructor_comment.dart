class InstructorComment {
  const InstructorComment({
    required this.id,
    required this.evaluationId,
    required this.instructorId,
    required this.comment,
    required this.type,
    required this.createdAt,
    this.stepNumber,
    this.instructorName = '',
    this.instructorAvatar,
  });

  final int id;
  final int evaluationId;
  final int instructorId;
  final String comment;
  final String type; // 'correcion' | 'felicitacion' | 'observacion'
  final int? stepNumber;
  final DateTime createdAt;
  final String instructorName;
  final String? instructorAvatar;
}
