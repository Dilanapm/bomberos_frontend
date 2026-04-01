import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../domain/entities/evaluation_detail.dart';
import '../providers/eval_detail_notifier.dart';

class EvalDetailScreen extends ConsumerWidget {
  const EvalDetailScreen({super.key, required this.evalId});
  final int evalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(evalDetailProvider(evalId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Evaluación #$evalId',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider: false,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final isNotFound = e.toString().contains('404') ||
              e.toString().toLowerCase().contains('not found');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNotFound
                        ? Icons.find_in_page_outlined
                        : Icons.cloud_off_rounded,
                    size: 56,
                    color: AppColors.secondary300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isNotFound
                        ? 'Evaluación no encontrada'
                        : 'Error al cargar la evaluación',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver al historial'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (detail) => _DetailBody(detail: detail, isDark: isDark),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.isDark});
  final EvaluationDetail detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(detail: detail, isDark: isDark),
        if (detail.recommendations != null &&
            detail.recommendations!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RecommendationCard(text: detail.recommendations!, isDark: isDark),
        ],
        if (detail.steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(text: 'Pasos', isDark: isDark),
          const SizedBox(height: 8),
          ...detail.steps.map((s) => _StepCard(step: s, isDark: isDark)),
        ],
        if (detail.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(text: 'Errores detectados', isDark: isDark),
          const SizedBox(height: 8),
          ...detail.errors.map((e) => _ErrorCard(err: e, isDark: isDark)),
        ],
        if (detail.comments.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(text: 'Comentarios del instructor', isDark: isDark),
          const SizedBox(height: 8),
          ...detail.comments
              .map((c) => _CommentCard(comment: c, isDark: isDark)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail, required this.isDark});
  final EvaluationDetail detail;
  final bool isDark;

  Color _statusColor(String s) {
    switch (s) {
      case 'aprobado':  return AppColors.success500;
      case 'reprobado': return AppColors.primary5;
      default:          return AppColors.accent400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? AppColors.cardDark : AppColors.white;
    final col      = _statusColor(detail.status);

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: col.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score + status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail.generalScore.toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: col,
                                ),
                      ),
                      Text(
                        'Puntaje general',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: col.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: col),
                  ),
                  child: Text(
                    detail.status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: col,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetaItem(
                  icon: Icons.timer_outlined,
                  label: 'Duración',
                  value: '${detail.durationSeconds.toStringAsFixed(1)}s',
                  isDark: isDark,
                ),
                _MetaItem(
                  icon: Icons.radar_rounded,
                  label: 'Detección',
                  value:
                      '${detail.detectionRate.toStringAsFixed(1)}%',
                  isDark: isDark,
                ),
                _MetaItem(
                  icon: detail.correctOrder
                      ? Icons.sort_rounded
                      : Icons.warning_amber_rounded,
                  label: 'Orden',
                  value: detail.correctOrder ? 'Correcto' : 'Incorrecto',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info500.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info500.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.info500, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary200
                        : AppColors.secondary700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isDark});
  final EvalStep step;
  final bool isDark;

  Color _statusColor(String s) {
    switch (s) {
      case 'correcto':       return AppColors.success500;
      case 'no_detectado':   return AppColors.secondary400;
      default:               return AppColors.primary5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.cardDark : AppColors.white;
    final col     = _statusColor(step.status);
    final pct     = (step.scorePercent / 100).clamp(0.0, 1.0);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step number
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: col.withAlpha(isDark ? 50 : 28),
                    shape: BoxShape.circle,
                    border: Border.all(color: col),
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: col,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.stepName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${step.scorePercent.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: col,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.secondary600 : AppColors.secondary100,
                valueColor: AlwaysStoppedAnimation<Color>(col),
              ),
            ),
            if (step.feedback != null && step.feedback!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                step.feedback!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.secondary400
                          : AppColors.secondary500,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${step.duration.toStringAsFixed(1)}s  ·  '
              '${step.detected ? "Detectado" : "No detectado"}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary500
                        : AppColors.secondary400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.err, required this.isDark});
  final EvalError err;
  final bool isDark;

  Color _severityColor(String s) {
    switch (s) {
      case 'alta':  return AppColors.primary5;
      case 'media': return AppColors.accent400;
      default:      return AppColors.secondary400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col    = _severityColor(err.severity);
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: col.withAlpha(60)),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: col.withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Paso ${err.stepNumber}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: col,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    err.description,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${err.errorType}  ·  severidad ${err.severity}',
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: col,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.isDark});
  final EvalComment comment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final date   = '${comment.createdAt.day.toString().padLeft(2, '0')}/'
                   '${comment.createdAt.month.toString().padLeft(2, '0')}/'
                   '${comment.createdAt.year}';

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      AppColors.info500.withAlpha(isDark ? 40 : 20),
                  child: const Icon(Icons.person_rounded,
                      size: 16, color: AppColors.info500),
                ),
                const SizedBox(width: 8),
                Text(
                  comment.instructorName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.secondary500
                            : AppColors.secondary400,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary200
                        : AppColors.secondary700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.secondary300 : AppColors.secondary600,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            size: 20,
            color: isDark ? AppColors.secondary300 : AppColors.secondary500),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    isDark ? AppColors.secondary400 : AppColors.secondary500,
              ),
        ),
      ],
    );
  }
}
