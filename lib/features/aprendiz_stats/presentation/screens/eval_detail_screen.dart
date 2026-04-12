import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../domain/entities/evaluation_detail.dart';
import '../providers/eval_detail_notifier.dart';

/// Colores según porcentaje de desempeño  
Color _scoreColor(double pct) {
  if (pct >= 75) return AppColors.success500; // Verde
  if (pct >= 50) return AppColors.accent400;  // Amarillo
  return AppColors.primary5;                  // Rojo
}

String _scoreLabel(double pct) {
  if (pct >= 75) return 'Correcto';
  if (pct >= 50) return 'Irregular';
  return 'No realizado';
}

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
    // Contar pasos clave (correctos + irregulares)
    final keySteps = detail.steps
        .where((s) => s.scorePercent >= 50) // >= 50% son clave
        .toList();
    final keyStepCount = keySteps.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(detail: detail, isDark: isDark),
        const SizedBox(height: 20),

        // Sección de puntos clave
        if (detail.steps.isNotEmpty) ...[
          _SectionHeader(
            text: '$keyStepCount PUNTOS CLAVE',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          ...detail.steps.map((s) => _StepCard(step: s, isDark: isDark)),
          const SizedBox(height: 20),
        ],

        // Comentarios del instructor
        if (detail.comments.isNotEmpty) ...[
          _SectionHeader(text: 'COMENTARIO DEL INSTRUCTOR', isDark: isDark),
          const SizedBox(height: 12),
          ...detail.comments
              .map((c) => _CommentCard(comment: c, isDark: isDark)),
          const SizedBox(height: 20),
        ],

        // Recomendaciones
        if (detail.recommendations != null &&
            detail.recommendations!.isNotEmpty) ...[
          _RecommendationCard(text: detail.recommendations!, isDark: isDark),
          const SizedBox(height: 20),
        ],

        // Errores
        if (detail.errors.isNotEmpty) ...[
          _SectionHeader(text: 'ERRORES DETECTADOS', isDark: isDark),
          const SizedBox(height: 12),
          ...detail.errors.map((e) => _ErrorCard(err: e, isDark: isDark)),
          const SizedBox(height: 20),
        ],

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Repetir entrenamiento
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Repetir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // Guardar reporte (aquí podrías llamar a PDF)
                },
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Guardar Reporte'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail, required this.isDark});
  final EvaluationDetail detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final col = _scoreColor(detail.generalScore);
    final label = _scoreLabel(detail.generalScore);
    
    // Formatear duración: convertir segundos a mm:ss
    final mins = (detail.durationSeconds / 60).floor();
    final secs = (detail.durationSeconds % 60).floor();
    final durationStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // Badge de estado
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: col.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col, width: 2),
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
        ),
        const SizedBox(height: 20),

        // Circular gauge con porcentaje
        Center(
          child: SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circulo de fondo
                CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: (detail.generalScore / 100).clamp(0.0, 1.0),
                    color: col,
                    backgroundColor:
                        isDark ? AppColors.secondary600 : AppColors.secondary100,
                    strokeWidth: 12,
                  ),
                  size: const Size(220, 220),
                ),
                // Porcentaje en el centro
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${detail.generalScore.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: col,
                            fontSize: 56,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Etiqueta de evaluación
        Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.secondary200
                      : AppColors.secondary700,
                ),
          ),
        ),
        const SizedBox(height: 4),

        // Duración
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Duración',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.secondary400
                          : AppColors.secondary500,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: isDark
                    ? AppColors.secondary400
                    : AppColors.secondary500,
              ),
              const SizedBox(width: 4),
              Text(
                durationStr,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter para dibujar el progeso circular (gauge/donut)
class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Círculo de fondo
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Arco de progreso (comienza desde arriba, va en sentido horario)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14159 / 180, // Comenzar desde arriba (-90°)
      progress * 2 * 3.14159, // Ángulo basado en progreso (0 a 360°)
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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

  @override
  Widget build(BuildContext context) {
    final pct = step.scorePercent;
    final col = _scoreColor(pct);
    final icon = pct >= 75
        ? Icons.check_circle_rounded
        : pct >= 50
            ? Icons.warning_rounded
            : Icons.cancel_rounded;

    // Formatear duración
    final mins = (step.duration / 60).floor();
    final secs = (step.duration % 60).floor();
    final durationStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Card(
      color: isDark ? AppColors.cardDark : AppColors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: col.withAlpha(60)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: icono + nombre + duración
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: col, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.stepName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      if (step.feedback != null && step.feedback!.isNotEmpty)
                        Text(
                          step.feedback!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.secondary400
                                    : AppColors.secondary500,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  durationStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.secondary400
                            : AppColors.secondary500,
                      ),
                ),
              ],
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
    final cardBg = isDark ? AppColors.cardDark : AppColors.secondary50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.secondary600 : AppColors.secondary200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comillas
          Text(
            '"',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.secondary400.withAlpha(100),
                  height: 0.8,
                ),
          ),
          const SizedBox(height: 4),

          // Comentario
          Text(
            comment.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.secondary200
                      : AppColors.secondary700,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 12),

          // Instructor info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary5.withAlpha(40),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppColors.primary5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.instructorName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'INSTRUCTOR JEFE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
            color: AppColors.primary5,
            letterSpacing: 0.5,
          ),
    );
  }
}
