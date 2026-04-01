import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/group_summary.dart';
import '../../domain/entities/need_help_data.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/entities/step_performance.dart';
import '../../data/repositories/stats_repository_impl.dart';

// ── Estado combinado de las 4 peticiones ─────────────────────────────────────

class StatsBundle {
  const StatsBundle({
    required this.groupSummary,
    required this.ranking,
    required this.needHelp,
    required this.steps,
  });

  final GroupSummary groupSummary;
  final List<RankingEntry> ranking;
  final NeedHelpData needHelp;
  final List<StepPerformance> steps;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StatsNotifier extends AsyncNotifier<StatsBundle> {
  @override
  Future<StatsBundle> build() => _fetch();

  Future<StatsBundle> _fetch() async {
    final repo = ref.read(statsRepositoryProvider);

    // Todos los endpoints en paralelo
    final results = await Future.wait([
      repo.getGroupSummary(),
      repo.getRanking(),
      repo.getNeedHelp(),
      repo.getStepAnalysis(),
    ]);

    return StatsBundle(
      groupSummary: results[0] as GroupSummary,
      ranking:      results[1] as List<RankingEntry>,
      needHelp:     results[2] as NeedHelpData,
      steps:        results[3] as List<StepPerformance>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final statsNotifierProvider =
    AsyncNotifierProvider<StatsNotifier, StatsBundle>(StatsNotifier.new);
