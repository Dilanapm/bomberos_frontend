import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/analytics_model.dart';
import '../models/eval_stats_model.dart';
import '../models/evaluation_detail_model.dart';
import '../models/evaluation_summary_model.dart';

class AprendizStatsRemoteDataSource {
  const AprendizStatsRemoteDataSource(this._dio);
  final Dio _dio;

  /// A1 — Dashboard principal
  Future<EvalStatsModel> fetchEvalStats() async {
    try {
      final res  = await _dio.get(ApiEndpoints.evalStats);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return EvalStatsModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// A2 — Análisis avanzado. Retorna null si data == null (sin evaluaciones).
  Future<AnalyticsModel?> fetchAnalytics() async {
    try {
      final res  = await _dio.get(ApiEndpoints.evalAnalytics);
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      if (data == null) return null;
      return AnalyticsModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// A3 — Historial paginado
  Future<EvalPageModel> fetchEvaluations({int page = 1}) async {
    try {
      final res  = await _dio.get(
        ApiEndpoints.evaluations,
        queryParameters: {'page': page},
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return EvalPageModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// A4 — Detalle de una evaluación
  Future<EvaluationDetailModel> fetchEvaluationDetail(int id) async {
    try {
      final res  = await _dio.get('${ApiEndpoints.evaluations}/$id');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return EvaluationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final aprendizStatsDsProvider = Provider<AprendizStatsRemoteDataSource>((ref) {
  return AprendizStatsRemoteDataSource(ref.read(dioClientProvider).dio);
});
