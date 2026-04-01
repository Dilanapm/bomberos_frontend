import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/eval_stats.dart';
import '../../data/repositories/aprendiz_stats_repository.dart';

class EvalStatsNotifier extends AsyncNotifier<EvalStats> {
  @override
  Future<EvalStats> build() =>
      ref.read(aprendizStatsRepoProvider).getEvalStats();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aprendizStatsRepoProvider).getEvalStats(),
    );
  }
}

final evalStatsProvider =
    AsyncNotifierProvider<EvalStatsNotifier, EvalStats>(EvalStatsNotifier.new);
