import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../domain/entities/instructor_evaluation.dart';
import '../providers/evaluations_notifier.dart';

class InstructorEvaluationsScreen extends ConsumerStatefulWidget {
  const InstructorEvaluationsScreen({super.key});

  @override
  ConsumerState<InstructorEvaluationsScreen> createState() =>
      _InstructorEvaluationsScreenState();
}

class _InstructorEvaluationsScreenState
    extends ConsumerState<InstructorEvaluationsScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl       = TextEditingController();
  final _searchFocus      = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    // No paginar mientras hay búsqueda activa.
    if (_query.isNotEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(evaluationsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final evalsAsync = ref.watch(evaluationsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Evaluaciones',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(evaluationsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda con sugerencias dinámicas ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: RawAutocomplete<InstructorEvaluation>(
              textEditingController: _searchCtrl,
              focusNode:             _searchFocus,
              optionsBuilder: (tv) {
                final q = tv.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<InstructorEvaluation>.empty();
                final evals =
                    ref.read(evaluationsNotifierProvider).value?.evaluations ?? [];
                return evals.where((e) =>
                    e.aprendizName.toLowerCase().contains(q) ||
                    e.aprendizUsername.toLowerCase().contains(q));
              },
              displayStringForOption: (e) => e.aprendizName,
              // ── Campo de texto ──────────────────────────────────────────────
              fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) => TextField(
                controller:      ctrl,
                focusNode:       focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted:     (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText:   'Buscar por nombre o usuario…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _searchFocus.unfocus();
                          },
                        )
                      : null,
                  filled:     true,
                  fillColor:  isDark ? AppColors.dark2 : AppColors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.secondary700
                          : AppColors.secondary200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.secondary700
                          : AppColors.secondary200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary5),
                  ),
                ),
              ),
              // ── Panel de sugerencias ────────────────────────────────────────
              optionsViewBuilder: (ctx, onSelected, options) {
                final cardBg =
                    isDark ? AppColors.dark2 : AppColors.white;
                final divColor =
                    isDark ? AppColors.dark3 : AppColors.secondary100;

                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation:    6,
                    color:        cardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        padding:    EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount:  options.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: divColor),
                        itemBuilder: (ctx, i) {
                          final eval = options.elementAt(i);
                          final scoreColor = eval.generalScore >= 75
                              ? AppColors.success500
                              : eval.generalScore >= 50
                                  ? AppColors.accent400
                                  : AppColors.primary5;

                          return InkWell(
                            borderRadius: i == 0
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(12))
                                : i == options.length - 1
                                    ? const BorderRadius.vertical(
                                        bottom: Radius.circular(12))
                                    : BorderRadius.zero,
                            onTap: () {
                              onSelected(eval); // llena el campo
                              context.push(
                                RouteNames.instructorEvalDetail,
                                extra: {'evalId': eval.id},
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius:          18,
                                    backgroundColor:
                                        AppColors.primary5.withAlpha(30),
                                    backgroundImage: eval.aprendizAvatar != null
                                        ? NetworkImage(eval.aprendizAvatar!)
                                        : null,
                                    child: eval.aprendizAvatar == null
                                        ? const Icon(Icons.person_rounded,
                                            color: AppColors.primary5, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          eval.aprendizName,
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '@${eval.aprendizUsername}',
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? AppColors.secondary400
                                                    : AppColors.secondary500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          scoreColor.withAlpha(isDark ? 40 : 20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: scoreColor, width: 1.2),
                                    ),
                                    child: Text(
                                      '${eval.generalScore.toStringAsFixed(0)}%',
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scoreColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Lista ───────────────────────────────────────────────────────────
          Expanded(
            child: evalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(evaluationsNotifierProvider.notifier).refresh(),
              ),
              data: (state) {
                // Filtrado local por nombre o username.
                final filtered = _query.isEmpty
                    ? state.evaluations
                    : state.evaluations
                        .where((e) =>
                            e.aprendizName
                                .toLowerCase()
                                .contains(_query) ||
                            e.aprendizUsername
                                .toLowerCase()
                                .contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return _query.isNotEmpty
                      ? _NoResultsView(query: _query, isDark: isDark)
                      : _EmptyView(isDark: isDark);
                }

                // Mostrar spinner de "cargando más" solo cuando no hay búsqueda.
                final showLoadMore =
                    _query.isEmpty && state.hasMore;

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(evaluationsNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16, 8, 16,
                      16 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    itemCount: filtered.length + (showLoadMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      if (i >= filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final eval = filtered[i];
                      return _EvalCard(
                        eval:   eval,
                        isDark: isDark,
                        onTap:  () => context.push(
                          RouteNames.instructorEvalDetail,
                          extra: {'evalId': eval.id},
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  const _EvalCard({
    required this.eval,
    required this.isDark,
    required this.onTap,
  });

  final InstructorEvaluation eval;
  final bool isDark;
  final VoidCallback onTap;

  static const _months = [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month]} ${d.year}';

  Color _scoreColor(double pct) {
    if (pct >= 75) return AppColors.success500;
    if (pct >= 50) return AppColors.accent400;
    return AppColors.primary5;
  }

  @override
  Widget build(BuildContext context) {
    final col        = _scoreColor(eval.generalScore);
    final dateStr    = _formatDate(eval.createdAt);
    final cardBg     = isDark ? AppColors.cardDark : AppColors.white;

    return Card(
      color:     cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.secondary700 : AppColors.secondary200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar del aprendiz
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary5.withAlpha(30),
                backgroundImage: eval.aprendizAvatar != null
                    ? NetworkImage(eval.aprendizAvatar!)
                    : null,
                child: eval.aprendizAvatar == null
                    ? const Icon(Icons.person_rounded,
                        color: AppColors.primary5, size: 26)
                    : null,
              ),
              const SizedBox(width: 14),

              // Nombre + fecha + comentarios
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.aprendizName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${eval.aprendizUsername}  ·  $dateStr',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.secondary400
                                : AppColors.secondary500,
                          ),
                    ),
                    if (eval.commentsCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 13,
                              color: isDark
                                  ? AppColors.secondary400
                                  : AppColors.secondary500),
                          const SizedBox(width: 4),
                          Text(
                            '${eval.commentsCount} comentario${eval.commentsCount > 1 ? 's' : ''}',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isDark
                                          ? AppColors.secondary400
                                          : AppColors.secondary500,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Score badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: col.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: col, width: 1.5),
                    ),
                    child: Text(
                      '${eval.generalScore.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: col,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color:
                        isDark ? AppColors.secondary400 : AppColors.secondary500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.query, required this.isDark});
  final String query;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: isDark ? AppColors.secondary600 : AppColors.secondary300),
          const SizedBox(height: 16),
          Text(
            'Sin resultados para "$query"',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64,
              color:
                  isDark ? AppColors.secondary600 : AppColors.secondary300),
          const SizedBox(height: 16),
          Text(
            'Sin evaluaciones aún',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.secondary300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar las evaluaciones',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary400,
                  ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary5),
            ),
          ],
        ),
      ),
    );
  }
}
