import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/evaluation_summary.dart';
import '../../data/repositories/aprendiz_stats_repository.dart';

// ── Estado del historial paginado ─────────────────────────────────────────────

class EvalHistoryState {
  const EvalHistoryState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoadingMore = false,
    this.error,
  });

  final List<EvaluationSummary> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;

  EvalHistoryState copyWith({
    List<EvaluationSummary>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return EvalHistoryState(
      items:         items         ?? this.items,
      currentPage:   currentPage   ?? this.currentPage,
      lastPage:      lastPage      ?? this.lastPage,
      total:         total         ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error:         clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class EvalHistoryNotifier extends AsyncNotifier<EvalHistoryState> {
  @override
  Future<EvalHistoryState> build() => _loadPage(1, reset: true);

  Future<EvalHistoryState> _loadPage(int page, {bool reset = false}) async {
    final result =
        await ref.read(aprendizStatsRepoProvider).getEvaluations(page: page);

    final previous = reset ? <EvaluationSummary>[] : (state.asData?.value.items ?? []);

    return EvalHistoryState(
      items:       [...previous, ...result.data],
      currentPage: result.currentPage,
      lastPage:    result.lastPage,
      total:       result.total,
    );
  }

  /// Carga la siguiente página (infinite scroll)
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(current.currentPage + 1);
      state = AsyncData(next);
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1, reset: true));
  }
}

final evalHistoryProvider =
    AsyncNotifierProvider<EvalHistoryNotifier, EvalHistoryState>(
        EvalHistoryNotifier.new);
