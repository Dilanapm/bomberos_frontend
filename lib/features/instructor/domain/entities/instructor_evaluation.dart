class InstructorEvaluation {
  const InstructorEvaluation({
    required this.id,
    required this.aprendizName,
    required this.aprendizUsername,
    required this.generalScore,
    required this.status,
    required this.createdAt,
    this.aprendizAvatar,
    this.commentsCount = 0,
  });

  final int id;
  final String aprendizName;
  final String aprendizUsername;
  final String? aprendizAvatar;
  final double generalScore;
  final String status;
  final DateTime createdAt;
  final int commentsCount;
}
