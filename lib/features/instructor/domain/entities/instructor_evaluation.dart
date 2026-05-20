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
    this.reviewed = false,
    this.scoreFinal,
  });

  final int id;
  final String aprendizName;
  final String aprendizUsername;
  final String? aprendizAvatar;
  final double generalScore;
  final String status;
  final DateTime createdAt;
  final int commentsCount;

  /// true si el instructor ya revisó y corrigió esta evaluación.
  final bool reviewed;

  /// Puntaje efectivo (instructor_final_score si existe, sino general_score).
  final double? scoreFinal;

  double get displayScore => scoreFinal ?? generalScore;
}
