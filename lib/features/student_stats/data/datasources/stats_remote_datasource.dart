import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/group_summary_model.dart';
import '../models/need_help_model.dart';
import '../models/ranking_entry_model.dart';
import '../models/step_performance_model.dart';

class StatsRemoteDataSource {
  const StatsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<GroupSummaryModel> fetchGroupSummary() async {
    try {
      final res = await _dio.get(ApiEndpoints.statsMyGroup);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return GroupSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<List<RankingEntryModel>> fetchRanking() async {
    try {
      final res  = await _dio.get(ApiEndpoints.statsRanking);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final list = (data['ranking'] as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(RankingEntryModel.fromJson).toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<NeedHelpDataModel> fetchNeedHelp() async {
    try {
      final res  = await _dio.get(ApiEndpoints.statsNeedHelp);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return NeedHelpDataModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<List<StepPerformanceModel>> fetchStepAnalysis() async {
    try {
      final res  = await _dio.get(ApiEndpoints.statsStepAnalysis);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final list = (data['pasos'] as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(StepPerformanceModel.fromJson).toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final statsRemoteDataSourceProvider = Provider<StatsRemoteDataSource>((ref) {
  return StatsRemoteDataSource(ref.read(dioClientProvider).dio);
});
