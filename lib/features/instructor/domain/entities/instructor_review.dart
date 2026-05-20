/// Payload para PATCH /instructor/evaluations/{id}/review

class InstructorReviewStep {
  const InstructorReviewStep({
    required this.stepNumber,
    this.instructorStatus,
    this.instructorScore,
    this.instructorNote,
  });

  final int stepNumber;

  /// "correcto" | "incorrecto" | null (sin cambio)
  final String? instructorStatus;

  /// 0.0–1.0 | null
  final double? instructorScore;

  /// Nota del instructor (máx 500 chars) | null
  final String? instructorNote;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'step_number': stepNumber};
    if (instructorStatus != null) map['instructor_status'] = instructorStatus;
    if (instructorScore != null)  map['instructor_score']  = instructorScore;
    if (instructorNote != null)   map['instructor_note']   = instructorNote;
    return map;
  }
}

class InstructorReviewPayload {
  const InstructorReviewPayload({
    this.instructorFinalScore,
    required this.steps,
  });

  /// Puntaje global final del instructor (0–100) | null = no cambiar
  final double? instructorFinalScore;

  /// Solo los pasos que el instructor quiere corregir
  final List<InstructorReviewStep> steps;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'steps': steps.map((s) => s.toJson()).toList(),
    };
    if (instructorFinalScore != null) {
      map['instructor_final_score'] = instructorFinalScore;
    }
    return map;
  }
}
