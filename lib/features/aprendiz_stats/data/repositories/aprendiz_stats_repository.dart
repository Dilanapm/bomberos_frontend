import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics.dart';
import '../../domain/entities/eval_stats.dart';
import '../../domain/entities/evaluation_detail.dart';
import '../../domain/entities/evaluation_summary.dart';
import '../datasources/aprendiz_stats_remote_datasource.dart';

class AprendizStatsRepository {
  const AprendizStatsRepository(this._ds);
  final AprendizStatsRemoteDataSource _ds;

  Future<EvalStats> getEvalStats() => _ds.fetchEvalStats();
  Future<Analytics?> getAnalytics() => _ds.fetchAnalytics();
  Future<EvalPage> getEvaluations({int page = 1}) =>
      _ds.fetchEvaluations(page: page);
  Future<EvaluationDetail> getEvaluationDetail(int id) =>
      _ds.fetchEvaluationDetail(id);
}

final aprendizStatsRepoProvider = Provider<AprendizStatsRepository>((ref) {
  return AprendizStatsRepository(ref.read(aprendizStatsDsProvider));
});
