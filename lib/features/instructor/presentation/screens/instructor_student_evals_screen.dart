import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../domain/entities/instructor_evaluation.dart';
import '../providers/evaluations_notifier.dart';

class InstructorStudentEvalsScreen extends ConsumerWidget {
  const InstructorStudentEvalsScreen({
    super.key,
    required this.aprendizUsername,
    required this.aprendizName,
    this.aprendizAvatar,
  });

  final String  aprendizUsername;
  final String  aprendizName;
  final String? aprendizAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final evalsAsync = ref.watch(evaluationsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title:           aprendizName,
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider:     false,
      ),
      body: evalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary400,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          // Filtramos solo las evaluaciones de este aprendiz, más recientes primero.
          final evals = state.evaluations
              .where((e) => e.aprendizUsername == aprendizUsername)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (evals.isEmpty) {
            return _EmptyEvals(isDark: isDark);
          }

          return Column(
            children: [
              // Encabezado con avatar + resumen
              _StudentHeader(
                name:      aprendizName,
                username:  aprendizUsername,
                avatarUrl: aprendizAvatar,
                evalCount: evals.length,
                isDark:    isDark,
              ),

              // Lista de evaluaciones
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16, 8, 16,
                    16 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  itemCount: evals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _EvalCard(
                    eval:   evals[i],
                    isDark: isDark,
                    onTap:  () => context.push(
                      RouteNames.instructorEvalDetail,
                      extra: {'evalId': evals[i].id},
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Encabezado del aprendiz
// ─────────────────────────────────────────────────────────────────────────────

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.name,
    required this.username,
    required this.evalCount,
    required this.isDark,
    this.avatarUrl,
  });

  final String  name;
  final String  username;
  final String? avatarUrl;
  final int     evalCount;
  final bool    isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subColor  = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final bgColor   = isDark ? AppColors.dark1 : AppColors.white;
    final border    = isDark ? AppColors.secondary700 : AppColors.secondary200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius:          30,
            backgroundColor: AppColors.primary5.withAlpha(30),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: textTheme.titleMedium?.copyWith(
                      color:      AppColors.primary5,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: textTheme.labelSmall?.copyWith(color: subColor),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 13, color: subColor),
                    const SizedBox(width: 4),
                    Text(
                      '$evalCount evaluación${evalCount != 1 ? 'es' : ''}',
                      style: textTheme.labelSmall?.copyWith(color: subColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de evaluación individual
// ─────────────────────────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  const _EvalCard({
    required this.eval,
    required this.isDark,
    required this.onTap,
  });

  final InstructorEvaluation eval;
  final bool                 isDark;
  final VoidCallback         onTap;

  static const _months = [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month]} ${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _scoreColor(double pct) {
    if (pct >= 75) return AppColors.success500;
    if (pct >= 50) return AppColors.accent400;
    return AppColors.primary5;
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'completed':
        return 'Completado';
      case 'pendiente':
      case 'pending':
        return 'Pendiente';
      case 'en_progreso':
      case 'in_progress':
        return 'En progreso';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'completed':
        return AppColors.success500;
      case 'pendiente':
      case 'pending':
        return AppColors.accent400;
      default:
        return AppColors.secondary400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cardBg    = isDark ? AppColors.cardDark : AppColors.white;
    final subColor  = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final scoreCol  = _scoreColor(eval.generalScore);
    final statCol   = _statusColor(eval.status);

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
              // ── Icono de evaluación ───────────────────────────────────────
              Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color:        AppColors.primary5.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size:  22,
                  color: AppColors.primary5,
                ),
              ),

              const SizedBox(width: 12),

              // ── Fecha + estado ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluación #${eval.id}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(eval.createdAt),
                            style: textTheme.labelSmall
                                ?.copyWith(color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:        statCol.withAlpha(isDark ? 40 : 20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(eval.status),
                            style: textTheme.labelSmall?.copyWith(
                              color:      statCol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (eval.commentsCount > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 12, color: subColor),
                          const SizedBox(width: 3),
                          Text(
                            '${eval.commentsCount}',
                            style: textTheme.labelSmall
                                ?.copyWith(color: subColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Promedio + chevron ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        scoreCol.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(color: scoreCol, width: 1.5),
                    ),
                    child: Text(
                      '${eval.generalScore.toStringAsFixed(0)}%',
                      style: textTheme.labelMedium?.copyWith(
                        color:      scoreCol,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: subColor),
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
// Estado vacío
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyEvals extends StatelessWidget {
  const _EmptyEvals({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size:  64,
            color: isDark ? AppColors.secondary600 : AppColors.secondary300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin evaluaciones aún',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este aprendiz no tiene evaluaciones registradas.',
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
