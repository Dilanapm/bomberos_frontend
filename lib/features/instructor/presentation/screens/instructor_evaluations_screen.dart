import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
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
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
    // Carga todas las páginas al entrar para que la lista de aprendices
    // esté completa desde el inicio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(evaluationsNotifierProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Agrupa evaluaciones por aprendiz y devuelve un resumen por alumno,
  /// ordenado por fecha de evaluación más reciente.
  List<StudentSummary> _buildStudents(List<InstructorEvaluation> evals) {
    final Map<String, List<InstructorEvaluation>> byStudent = {};
    for (final e in evals) {
      (byStudent[e.aprendizUsername] ??= []).add(e);
    }
    final students = byStudent.entries.map((entry) {
      final list = entry.value
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final avg =
          list.fold(0.0, (s, e) => s + e.generalScore) / list.length;
      return StudentSummary(
        name:         list.first.aprendizName,
        username:     entry.key,
        avatarUrl:    list.first.aprendizAvatar,
        evalCount:    list.length,
        lastEvalDate: list.first.createdAt,
        avgScore:     avg,
      );
    }).toList()
      ..sort((a, b) => b.lastEvalDate.compareTo(a.lastEvalDate));
    return students;
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final evalsAsync = ref.watch(evaluationsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title:           'Evaluaciones',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider:     false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await ref
                  .read(evaluationsNotifierProvider.notifier)
                  .refresh();
              ref
                  .read(evaluationsNotifierProvider.notifier)
                  .loadAll();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller:      _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:   'Buscar aprendiz…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled:    true,
                fillColor: isDark ? AppColors.dark2 : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary5),
                ),
              ),
            ),
          ),

          // ── Lista ───────────────────────────────────────────────────────
          Expanded(
            child: evalsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () async {
                  await ref
                      .read(evaluationsNotifierProvider.notifier)
                      .refresh();
                  ref
                      .read(evaluationsNotifierProvider.notifier)
                      .loadAll();
                },
              ),
              data: (state) {
                final students = _buildStudents(state.evaluations);

                // Filtrado por nombre o username.
                final filtered = _query.isEmpty
                    ? students
                    : students
                        .where((s) =>
                            s.name
                                .toLowerCase()
                                .contains(_query) ||
                            s.username
                                .toLowerCase()
                                .contains(_query))
                        .toList();

                if (students.isEmpty) {
                  return _EmptyView(
                    isLoading: state.loadingMore,
                    isDark: isDark,
                  );
                }

                if (filtered.isEmpty) {
                  return _NoResultsView(
                      query: _query, isDark: isDark);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(evaluationsNotifierProvider.notifier)
                        .refresh();
                    ref
                        .read(evaluationsNotifierProvider.notifier)
                        .loadAll();
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16, 8, 16,
                      16 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    itemCount: filtered.length +
                        (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      if (i >= filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      final student = filtered[i];
                      return _StudentCard(
                        student: student,
                        isDark:  isDark,
                        onTap:   () => context.push(
                          RouteNames.instructorStudentEvals,
                          extra: {
                            'aprendizUsername': student.username,
                            'aprendizName':     student.name,
                            'aprendizAvatar':   student.avatarUrl,
                          },
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
// Tarjeta de aprendiz
// ─────────────────────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.isDark,
    required this.onTap,
  });

  final StudentSummary student;
  final bool           isDark;
  final VoidCallback   onTap;

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
    final textTheme = Theme.of(context).textTheme;
    final cardBg    = isDark ? AppColors.cardDark : AppColors.white;
    final col       = _scoreColor(student.avgScore);
    final dateStr   = _formatDate(student.lastEvalDate);
    final subColor  =
        isDark ? AppColors.secondary400 : AppColors.secondary500;

    return Card(
      color:     cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              isDark ? AppColors.secondary700 : AppColors.secondary200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────
              CircleAvatar(
                radius:          24,
                backgroundColor: AppColors.primary5.withAlpha(30),
                backgroundImage: student.avatarUrl != null
                    ? NetworkImage(student.avatarUrl!)
                    : null,
                child: student.avatarUrl == null
                    ? Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.primary5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              // ── Nombre + username + resumen ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${student.username}',
                      style: textTheme.labelSmall
                          ?.copyWith(color: subColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 13, color: subColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${student.evalCount} evaluación${student.evalCount != 1 ? 'es' : ''}',
                            style: textTheme.labelSmall
                                ?.copyWith(color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded,
                            size: 13, color: subColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateStr,
                            style: textTheme.labelSmall
                                ?.copyWith(color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Promedio + chevron ─────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          col.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: col, width: 1.5),
                    ),
                    child: Text(
                      '${student.avgScore.toStringAsFixed(0)}%',
                      style: textTheme.labelMedium?.copyWith(
                        color: col,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: subColor,
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

// ─────────────────────────────────────────────────────────────────────────────
// Estados vacíos / error
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isLoading, required this.isDark});
  final bool isLoading;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined,
              size: 64,
              color: isDark
                  ? AppColors.secondary600
                  : AppColors.secondary300),
          const SizedBox(height: 16),
          Text(
            'Sin aprendices aún',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tus aprendices realicen\nevaluaciones aparecerán aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.secondary500
                      : AppColors.secondary400,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.query, required this.isDark});
  final String query;
  final bool   isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: isDark
                  ? AppColors.secondary600
                  : AppColors.secondary300),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String       message;
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
              icon:  const Icon(Icons.refresh_rounded),
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
