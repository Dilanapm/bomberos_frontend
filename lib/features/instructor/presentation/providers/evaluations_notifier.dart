import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/instructor_evaluations_datasource.dart';
import '../../domain/entities/instructor_comment.dart';
import '../../domain/entities/instructor_evaluation.dart';

// ── Estado paginado de evaluaciones ──────────────────────────────────────────

class EvaluationsState {
  const EvaluationsState({
    required this.evaluations,
    this.currentPage = 1,
    this.lastPage = 1,
    this.loadingMore = false,
  });

  final List<InstructorEvaluation> evaluations;
  final int currentPage;
  final int lastPage;
  final bool loadingMore;

  bool get hasMore => currentPage < lastPage;

  EvaluationsState copyWith({
    List<InstructorEvaluation>? evaluations,
    int? currentPage,
    int? lastPage,
    bool? loadingMore,
  }) =>
      EvaluationsState(
        evaluations: evaluations ?? this.evaluations,
        currentPage: currentPage ?? this.currentPage,
        lastPage:    lastPage    ?? this.lastPage,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class EvaluationsNotifier extends AsyncNotifier<EvaluationsState> {
  /// Guard de instancia — se pone a `true` antes del primer `await` para que
  /// ningún evento de scroll concurrente pueda disparar otra llamada.
  bool _isFetching = false;

  @override
  Future<EvaluationsState> build() async {
    _isFetching = false; // reinicia al reconstruir
    final result = await ref
        .read(instructorEvaluationsDSProvider)
        .fetchEvaluations(page: 1);
    return EvaluationsState(
      evaluations: result.items,
      currentPage: 1,
      lastPage:    result.lastPage,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _isFetching) return;

    // Guard síncrono: se activa ANTES del primer await.
    _isFetching = true;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await ref
          .read(instructorEvaluationsDSProvider)
          .fetchEvaluations(page: nextPage);

      // Usa el estado MÁS RECIENTE (no el snapshot `current`) para evitar
      // sobrescribir cambios que pudieran haberse producido durante el await.
      final latest = state.value ?? current;
      final existingIds = latest.evaluations.map((e) => e.id).toSet();
      final newItems =
          result.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncData(latest.copyWith(
        evaluations: [...latest.evaluations, ...newItems],
        currentPage: nextPage,
        lastPage:    result.lastPage,
        loadingMore: false,
      ));
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(loadingMore: false));
    } finally {
      _isFetching = false;
    }
  }
}

final evaluationsNotifierProvider =
    AsyncNotifierProvider<EvaluationsNotifier, EvaluationsState>(
        EvaluationsNotifier.new);

// ── Estado de comentarios de una evaluación específica ────────────────────────

class CommentsState {
  const CommentsState({
    required this.comments,
    this.submitting = false,
    this.errorMessage,
  });

  final List<InstructorComment> comments;
  final bool submitting;
  final String? errorMessage;

  CommentsState copyWith({
    List<InstructorComment>? comments,
    bool? submitting,
    String? errorMessage,
  }) =>
      CommentsState(
        comments:     comments     ?? this.comments,
        submitting:   submitting   ?? this.submitting,
        errorMessage: errorMessage,
      );
}

// Riverpod 3: el arg se pasa por constructor; build() no recibe parámetros.
class CommentsNotifier extends AsyncNotifier<CommentsState> {
  CommentsNotifier(this._evalId);
  final int _evalId;

  @override
  Future<CommentsState> build() async {
    final list = await ref
        .read(instructorEvaluationsDSProvider)
        .fetchComments(_evalId);
    return CommentsState(comments: list);
  }

  Future<void> addComment({
    required String comment,
    required String type,
    int? stepNumber,
  }) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(submitting: true));
    try {
      final newComment = await ref
          .read(instructorEvaluationsDSProvider)
          .addComment(
            evalId:     _evalId,
            comment:    comment,
            type:       type,
            stepNumber: stepNumber,
          );
      state = AsyncData(current.copyWith(
        submitting: false,
        comments:   [newComment, ...current.comments],
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(
        submitting:   false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteComment(int commentId) async {
    final current = state.value;
    if (current == null) return;

    try {
      await ref
          .read(instructorEvaluationsDSProvider)
          .deleteComment(evalId: _evalId, commentId: commentId);
      state = AsyncData(current.copyWith(
        comments: current.comments
            .where((c) => c.id != commentId)
            .toList(),
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(errorMessage: e.toString()));
    }
  }
}

// CommentsNotifier.new es CommentsNotifier Function(int) → coincide con
// NotifierT Function(ArgT arg) que exige AsyncNotifierProvider.family.
final commentsNotifierProvider =
    AsyncNotifierProvider.family<CommentsNotifier, CommentsState, int>(
        CommentsNotifier.new);
