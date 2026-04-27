import '../../domain/entities/evaluation_detail.dart';

/// Safely parses a value that may arrive as String or num from the API.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());
int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.parse(v.toString());

/// Parses a value that can be num, String, or null.
double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class EvalStepModel extends EvalStep {
  const EvalStepModel({
    required super.stepNumber,
    required super.stepName,
    required super.score,
    required super.status,
    required super.detected,
    super.feedback,
    super.timeStart,
    super.timeEnd,
    super.duration,
    super.peakTime,
    super.peakConfidence,
    super.detectionType,
  });

  factory EvalStepModel.fromJson(Map<String, dynamic> json) {
    return EvalStepModel(
      stepNumber:     _toInt(json['step_number']),
      stepName:        json['step_name']       as String,
      score:          _toDouble(json['score']),
      status:          json['status']          as String,
      detected:        json['detected']        as bool? ?? false,
      feedback:        json['feedback']        as String?,
      timeStart:      _toDoubleOrNull(json['time_start']),
      timeEnd:        _toDoubleOrNull(json['time_end']),
      duration:       _toDoubleOrNull(json['duration']),
      peakTime:       _toDoubleOrNull(json['peak_time']),
      peakConfidence: _toDoubleOrNull(json['peak_confidence']),
      detectionType:   json['detection_type']  as String?,
    );
  }
}

class EvalErrorModel extends EvalError {
  const EvalErrorModel({
    required super.stepNumber,
    required super.errorType,
    required super.description,
    required super.severity,
  });

  factory EvalErrorModel.fromJson(Map<String, dynamic> json) {
    return EvalErrorModel(
      stepNumber:  _toInt(json['step_number']),
      errorType:    json['error_type']  as String,
      description:  json['description'] as String,
      severity:     json['severity']    as String,
    );
  }
}

class EvalCommentModel extends EvalComment {
  const EvalCommentModel({
    required super.id,
    required super.comment,
    required super.instructorId,
    required super.instructorName,
    required super.createdAt,
  });

  factory EvalCommentModel.fromJson(Map<String, dynamic> json) {
    final inst = json['instructor'] as Map<String, dynamic>? ?? {};
    return EvalCommentModel(
      id:             _toInt(json['id']),
      comment:         json['comment']     as String,
      instructorId:   _toInt(inst['id'] ?? 0),
      instructorName:  inst['name']        as String? ?? '',
      createdAt:      DateTime.parse(json['created_at'] as String),
    );
  }
}

class EvaluationDetailModel extends EvaluationDetail {
  const EvaluationDetailModel({
    required super.id,
    required super.generalScore,
    required super.status,
    required super.durationSeconds,
    required super.detectionRate,
    required super.correctOrder,
    super.recommendations,
    required super.steps,
    required super.errors,
    required super.comments,
  });

  factory EvaluationDetailModel.fromJson(Map<String, dynamic> json) {
    return EvaluationDetailModel(
      id:             _toInt(json['id']),
      generalScore:   _toDouble(json['general_score']),
      status:          json['status']          as String,
      durationSeconds: _toDouble(json['duration_seconds']),
      detectionRate:   _toDouble(json['detection_rate']),
      correctOrder:    json['correct_order']   as bool? ?? false,
      recommendations: json['recommendations'] as String?,
      steps: ((json['steps'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(EvalStepModel.fromJson)
          .toList(),
      errors: ((json['errors'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(EvalErrorModel.fromJson)
          .toList(),
      comments: ((json['comments'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(EvalCommentModel.fromJson)
          .toList(),
    );
  }
}
