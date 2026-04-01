/// Dashboard principal del aprendiz — GET /evaluations/stats (A1)

class EvalStats {
  const EvalStats({
    required this.totalAttempts,
    required this.approved,
    required this.failed,
    required this.passRate,
    required this.averageScore,
    required this.bestScore,
    required this.resultadoMasComun,
    required this.rangoTipico,
    required this.nivelConsistencia,
    required this.interpretacionConsistencia,
    required this.comparacionGrupo,
    this.lastEvaluation,
    this.hardestStep,
    required this.progress,
  });

  final int totalAttempts;
  final int approved;
  final int failed;
  final double passRate;
  final double averageScore;
  final double bestScore;

  final double resultadoMasComun;
  /// e.g. "±3.6" — returned as a formatted string by the API
  final String rangoTipico;

  /// "alta" | "moderada" | "baja"
  final String nivelConsistencia;
  final String interpretacionConsistencia;

  final StatsGroupComparison comparacionGrupo;
  final LastEvaluation? lastEvaluation;
  final HardestStep? hardestStep;

  /// Puntos del gráfico de progreso (orden cronológico)
  final List<ProgressPoint> progress;
}

class StatsGroupComparison {
  const StatsGroupComparison({
    required this.miPromedio,
    required this.promedioGrupo,
    required this.diferencia,
    required this.interpretacion,
  });

  final double miPromedio;
  final double promedioGrupo;
  final double diferencia;
  final String interpretacion;
}

class LastEvaluation {
  const LastEvaluation({
    required this.id,
    required this.generalScore,
    required this.status,
    required this.stepsCompleted,
    required this.createdAt,
  });

  final int id;
  final double generalScore;
  final String status;
  final int stepsCompleted;
  final DateTime createdAt;
}

class HardestStep {
  const HardestStep({
    required this.stepNumber,
    required this.stepName,
    required this.avgScore,
    required this.attempts,
  });

  final int stepNumber;
  final String stepName;
  final double avgScore;
  final int attempts;
}

class ProgressPoint {
  const ProgressPoint({
    required this.id,
    required this.generalScore,
    required this.status,
    required this.stepsCompleted,
    required this.createdAt,
  });

  final int id;
  final double generalScore;
  final String status;
  final int stepsCompleted;
  final DateTime createdAt;
}
