// Item del historial paginado — GET /evaluations?page=N (A3)

class EvaluationSummary {
  const EvaluationSummary({
    required this.id,
    this.sessionId,
    required this.generalScore,
    required this.totalSteps,
    required this.stepsCompleted,
    required this.correctOrder,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String? sessionId;
  final double generalScore;
  final int totalSteps;
  final int stepsCompleted;
  final bool correctOrder;

  /// "aprobado" | "reprobado" | "incompleto"
  final String status;
  final DateTime createdAt;
}

/// Wrapper de la respuesta paginada
class EvalPage {
  const EvalPage({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.data,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final List<EvaluationSummary> data;

  bool get hasMore => currentPage < lastPage;
}
