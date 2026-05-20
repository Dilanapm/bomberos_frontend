import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../aprendiz_stats/data/models/evaluation_detail_model.dart';
import '../../domain/entities/instructor_review.dart';
import '../models/instructor_comment_model.dart';
import '../models/instructor_evaluation_model.dart';

class InstructorEvaluationsDataSource {
  const InstructorEvaluationsDataSource(this._dio);
  final Dio _dio;

  /// Retorna una página de evaluaciones.
  /// [page] = número de página (por defecto 1).
  /// Devuelve ({evaluaciones, últimaPágina}) para soportar paginación.
  Future<({List<InstructorEvaluationModel> items, int lastPage})>
      fetchEvaluations({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.instructorEvaluations,
        queryParameters: {'page': page},
      );
      final body     = res.data as Map<String, dynamic>;
      final paginator = body['data'] as Map<String, dynamic>;
      final list     = (paginator['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(InstructorEvaluationModel.fromJson)
          .toList();
      final lastPage = (paginator['last_page'] as num?)?.toInt() ?? 1;
      return (items: list, lastPage: lastPage);
    } on DioException catch (e) {
      throw _unwrap(e);
    } catch (e, st) {
      debugPrint('[Evaluations] parse error: $e\n$st');
      throw UnknownException('Error al procesar evaluaciones: $e');
    }
  }

  Future<List<InstructorCommentModel>> fetchComments(int evalId) async {
    try {
      final res  = await _dio.get(ApiEndpoints.instructorEvalComments(evalId));
      final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(InstructorCommentModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<InstructorCommentModel> addComment({
    required int evalId,
    required String comment,
    required String type,
    int? stepNumber,
  }) async {
    try {
      final body = <String, dynamic>{
        'comment': comment,
        'type': type,
        if (stepNumber != null) 'step_number': stepNumber,
      };
      final res  = await _dio.post(ApiEndpoints.instructorEvalComments(evalId), data: body);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return InstructorCommentModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> deleteComment({required int evalId, required int commentId}) async {
    try {
      await _dio.delete(ApiEndpoints.instructorDeleteComment(evalId, commentId));
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// GET /instructor/evaluations/{id} — detalle completo de una evaluación.
  Future<EvaluationDetailModel> fetchEvalDetail(int evalId) async {
    try {
      final res  = await _dio.get(ApiEndpoints.instructorEvalDetail(evalId));
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return EvaluationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    } catch (e, st) {
      debugPrint('[EvalDetail] parse error: $e\n$st');
      throw UnknownException('Error al procesar detalle: $e');
    }
  }

  /// PATCH /instructor/evaluations/{id}/review — envía revisión del instructor.
  Future<void> reviewEvaluation({
    required int evalId,
    required InstructorReviewPayload payload,
  }) async {
    try {
      await _dio.patch(
        ApiEndpoints.instructorEvalReview(evalId),
        data: payload.toJson(),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final instructorEvaluationsDSProvider =
    Provider<InstructorEvaluationsDataSource>((ref) {
  return InstructorEvaluationsDataSource(ref.read(dioClientProvider).dio);
});
