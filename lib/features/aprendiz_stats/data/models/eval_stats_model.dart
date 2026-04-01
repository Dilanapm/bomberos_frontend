import '../../domain/entities/eval_stats.dart';

/// Safely parses a value that may arrive as String or num from the API.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());
int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.parse(v.toString());

class StatsGroupComparisonModel extends StatsGroupComparison {
  const StatsGroupComparisonModel({
    required super.miPromedio,
    required super.promedioGrupo,
    required super.diferencia,
    required super.interpretacion,
  });

  factory StatsGroupComparisonModel.fromJson(Map<String, dynamic> json) {
    return StatsGroupComparisonModel(
      miPromedio:    _toDouble(json['mi_promedio']),
      promedioGrupo: _toDouble(json['promedio_grupo']),
      diferencia:    _toDouble(json['diferencia']),
      interpretacion: json['interpretacion'] as String,
    );
  }
}

class LastEvaluationModel extends LastEvaluation {
  const LastEvaluationModel({
    required super.id,
    required super.generalScore,
    required super.status,
    required super.stepsCompleted,
    required super.createdAt,
  });

  factory LastEvaluationModel.fromJson(Map<String, dynamic> json) {
    return LastEvaluationModel(
      id:             _toInt(json['id']),
      generalScore:   _toDouble(json['general_score']),
      status:          json['status']            as String,
      stepsCompleted: _toInt(json['steps_completed']),
      createdAt:      DateTime.parse(json['created_at'] as String),
    );
  }
}

class HardestStepModel extends HardestStep {
  const HardestStepModel({
    required super.stepNumber,
    required super.stepName,
    required super.avgScore,
    required super.attempts,
  });

  factory HardestStepModel.fromJson(Map<String, dynamic> json) {
    return HardestStepModel(
      stepNumber: _toInt(json['step_number']),
      stepName:    json['step_name']   as String,
      avgScore:   _toDouble(json['avg_score']),
      attempts:   _toInt(json['attempts']),
    );
  }
}

class ProgressPointModel extends ProgressPoint {
  const ProgressPointModel({
    required super.id,
    required super.generalScore,
    required super.status,
    required super.stepsCompleted,
    required super.createdAt,
  });

  factory ProgressPointModel.fromJson(Map<String, dynamic> json) {
    return ProgressPointModel(
      id:             _toInt(json['id']),
      generalScore:   _toDouble(json['general_score']),
      status:          json['status']         as String,
      stepsCompleted: _toInt(json['steps_completed']),
      createdAt:      DateTime.parse(json['created_at'] as String),
    );
  }
}

class EvalStatsModel extends EvalStats {
  const EvalStatsModel({
    required super.totalAttempts,
    required super.approved,
    required super.failed,
    required super.passRate,
    required super.averageScore,
    required super.bestScore,
    required super.resultadoMasComun,
    required super.rangoTipico,
    required super.nivelConsistencia,
    required super.interpretacionConsistencia,
    required super.comparacionGrupo,
    super.lastEvaluation,
    super.hardestStep,
    required super.progress,
  });

  factory EvalStatsModel.fromJson(Map<String, dynamic> json) {
    final lastJson    = json['last_evaluation']  as Map<String, dynamic>?;
    final hardestJson = json['hardest_step']     as Map<String, dynamic>?;
    final progressRaw = json['progress']         as List<dynamic>? ?? [];

    return EvalStatsModel(
      totalAttempts:             _toInt(json['total_attempts']),
      approved:                  _toInt(json['approved']),
      failed:                    _toInt(json['failed']),
      passRate:                  _toDouble(json['pass_rate']),
      averageScore:              _toDouble(json['average_score']),
      bestScore:                 _toDouble(json['best_score']),
      resultadoMasComun:         _toDouble(json['resultado_mas_comun']),
      rangoTipico:               json['rango_tipico']              as String,
      nivelConsistencia:          json['nivel_consistencia']        as String,
      interpretacionConsistencia: json['interpretacion_consistencia'] as String,
      comparacionGrupo: StatsGroupComparisonModel.fromJson(
          json['comparacion_grupo'] as Map<String, dynamic>),
      lastEvaluation: lastJson != null
          ? LastEvaluationModel.fromJson(lastJson)
          : null,
      hardestStep: hardestJson != null
          ? HardestStepModel.fromJson(hardestJson)
          : null,
      progress: progressRaw
          .cast<Map<String, dynamic>>()
          .map(ProgressPointModel.fromJson)
          .toList(),
    );
  }
}
