import '../../domain/entities/evaluation_summary.dart';

/// Safely parses a value that may arrive as String or num from the API.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());
int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.parse(v.toString());

class EvaluationSummaryModel extends EvaluationSummary {
  const EvaluationSummaryModel({
    required super.id,
    super.sessionId,
    required super.generalScore,
    required super.totalSteps,
    required super.stepsCompleted,
    required super.correctOrder,
    required super.status,
    required super.createdAt,
  });

  factory EvaluationSummaryModel.fromJson(Map<String, dynamic> json) {
    return EvaluationSummaryModel(
      id:             _toInt(json['id']),
      sessionId:       json['session_id']      as String?,
      generalScore:   _toDouble(json['general_score']),
      totalSteps:     _toInt(json['total_steps']),
      stepsCompleted: _toInt(json['steps_completed']),
      correctOrder:    json['correct_order']   as bool? ?? false,
      status:          json['status']          as String,
      createdAt:      DateTime.parse(json['created_at'] as String),
    );
  }
}

class EvalPageModel extends EvalPage {
  const EvalPageModel({
    required super.currentPage,
    required super.perPage,
    required super.total,
    required super.lastPage,
    required super.data,
  });

  factory EvalPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(EvaluationSummaryModel.fromJson)
        .toList();

    return EvalPageModel(
      currentPage: _toInt(json['current_page']),
      perPage:     _toInt(json['per_page']),
      total:       _toInt(json['total']),
      lastPage:    _toInt(json['last_page']),
      data:         items,
    );
  }
}
