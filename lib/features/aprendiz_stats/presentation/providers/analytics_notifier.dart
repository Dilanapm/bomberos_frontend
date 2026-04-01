import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics.dart';
import '../../data/repositories/aprendiz_stats_repository.dart';

/// Retorna null si el aprendiz no tiene evaluaciones aún.
class AnalyticsNotifier extends AsyncNotifier<Analytics?> {
  @override
  Future<Analytics?> build() =>
      ref.read(aprendizStatsRepoProvider).getAnalytics();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aprendizStatsRepoProvider).getAnalytics(),
    );
  }
}

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, Analytics?>(AnalyticsNotifier.new);
