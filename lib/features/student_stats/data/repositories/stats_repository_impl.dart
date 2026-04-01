import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/group_summary.dart';
import '../../domain/entities/need_help_data.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/entities/step_performance.dart';
import '../datasources/stats_remote_datasource.dart';

class StatsRepository {
  const StatsRepository(this._ds);
  final StatsRemoteDataSource _ds;

  Future<GroupSummary> getGroupSummary() => _ds.fetchGroupSummary();
  Future<List<RankingEntry>> getRanking() => _ds.fetchRanking();
  Future<NeedHelpData> getNeedHelp() => _ds.fetchNeedHelp();
  Future<List<StepPerformance>> getStepAnalysis() => _ds.fetchStepAnalysis();
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.read(statsRemoteDataSourceProvider));
});
