/// Detalle completo de una evaluación — GET /evaluations/{id} (A4)

class EvaluationDetail {
  const EvaluationDetail({
    required this.id,
    required this.generalScore,
    required this.status,
    required this.durationSeconds,
    required this.detectionRate,
    required this.correctOrder,
    this.recommendations,
    required this.steps,
    required this.errors,
    required this.comments,
  });

  final int id;
  final double generalScore;

  /// "aprobado" | "reprobado" | "incompleto"
  final String status;
  final double durationSeconds;
  final double detectionRate;
  final bool correctOrder;
  final String? recommendations;

  final List<EvalStep> steps;
  final List<EvalError> errors;
  final List<EvalComment> comments;
}

class EvalStep {
  const EvalStep({
    required this.stepNumber,
    required this.stepName,
    required this.score,
    required this.status,
    required this.detected,
    this.feedback,
    this.timeStart,
    this.timeEnd,
    this.duration,
    this.peakTime,
    this.peakConfidence,
    this.detectionType,
  });

  final int stepNumber;
  final String stepName;

  /// 0.0–1.0 → multiplicar × 100 para porcentaje
  final double score;

  /// "correcto" | "incorrecto" | "no_detectado"
  final String status;
  final bool detected;
  final String? feedback;

  // Tiempos — null cuando el paso no fue detectado
  final double? timeStart;
  final double? timeEnd;
  final double? duration;

  // Campos adicionales de FastAPI
  final double? peakTime;        // segundo del frame con mayor confianza
  final double? peakConfidence;  // confianza máxima (0..1)
  final String? detectionType;   // "instant" | "segment" | null

  double get scorePercent => score * 100;
}

class EvalError {
  const EvalError({
    required this.stepNumber,
    required this.errorType,
    required this.description,
    required this.severity,
  });

  final int stepNumber;
  final String errorType;
  final String description;

  /// "alta" | "media" | "baja"
  final String severity;
}

class EvalComment {
  const EvalComment({
    required this.id,
    required this.comment,
    required this.instructorId,
    required this.instructorName,
    required this.createdAt,
  });

  final int id;
  final String comment;
  final int instructorId;
  final String instructorName;
  final DateTime createdAt;
}
