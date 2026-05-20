import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/eval_stats.dart';
import '../../domain/entities/evaluation_summary.dart';
import '../providers/analytics_notifier.dart';
import '../providers/eval_history_notifier.dart';
import '../providers/eval_stats_notifier.dart';
import '../services/stats_pdf_service.dart';

class AprendizStatsScreen extends ConsumerStatefulWidget {
  const AprendizStatsScreen({super.key});

  @override
  ConsumerState<AprendizStatsScreen> createState() =>
      _AprendizStatsScreenState();
}

class _AprendizStatsScreenState extends ConsumerState<AprendizStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Mis Estadísticas',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.primary1,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded),   text: 'Resumen'),
            Tab(icon: Icon(Icons.insights_rounded),     text: 'Análisis'),
            Tab(icon: Icon(Icons.history_rounded),      text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DashboardTab(isDark: isDark),
          _AnalyticsTab(isDark: isDark),
          _HistoryTab(isDark: isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPdfOptions(context, ref),
        backgroundColor: AppColors.primary5,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.white),
        label: const Text('Generar PDF', style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  // ── Diálogo para elegir tipo de PDF ──────────────────────────────────────
  void _showPdfOptions(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.read(authNotifierProvider).asData?.value;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'Aprendiz';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.dark1 : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generar Reporte PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.dark0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el tipo de reporte',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.dark4 : AppColors.secondary500,
                ),
              ),
              const SizedBox(height: 16),
              _PdfOptionTile(
                icon: Icons.dashboard_rounded,
                title: 'Resumen',
                subtitle: 'Estadísticas generales y progreso',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _generateResumenPdf(ref, userName);
                },
              ),
              _PdfOptionTile(
                icon: Icons.insights_rounded,
                title: 'Análisis',
                subtitle: 'Fortalezas, debilidades y tendencia',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _generateAnalisisPdf(ref, userName);
                },
              ),
              _PdfOptionTile(
                icon: Icons.history_rounded,
                title: 'Historial',
                subtitle: 'Lista de todas las evaluaciones',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _generateHistorialPdf(ref, userName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateResumenPdf(WidgetRef ref, String userName) async {
    final statsAV = ref.read(evalStatsProvider);
    final stats = statsAV.asData?.value;
    if (stats == null) {
      _snack('No hay datos de resumen disponibles', isError: true);
      return;
    }
    await _buildAndSharePdf(
      title: 'Resumen',
      fileName: 'reporte_resumen.pdf',
      generate: () => StatsPdfService.generateResumen(
        stats: stats,
        userName: userName,
      ),
    );
  }

  Future<void> _generateAnalisisPdf(WidgetRef ref, String userName) async {
    final analyticsAV = ref.read(analyticsProvider);
    final analytics = analyticsAV.asData?.value;
    if (analytics == null) {
      _snack('No hay datos de análisis disponibles', isError: true);
      return;
    }
    await _buildAndSharePdf(
      title: 'Análisis',
      fileName: 'reporte_analisis.pdf',
      generate: () => StatsPdfService.generateAnalisis(
        analytics: analytics,
        userName: userName,
      ),
    );
  }

  Future<void> _generateHistorialPdf(WidgetRef ref, String userName) async {
    final historyState = ref.read(evalHistoryProvider).asData?.value;
    if (historyState == null || historyState.items.isEmpty) {
      _snack('No hay evaluaciones disponibles', isError: true);
      return;
    }
    await _buildAndSharePdf(
      title: 'Historial',
      fileName: 'reporte_historial.pdf',
      generate: () => StatsPdfService.generateHistorial(
        evaluations: historyState.items,
        userName: userName,
      ),
    );
  }

  /// Genera el PDF mostrando un diálogo de carga y luego abre la vista
  /// previa / compartir del sistema.
  Future<void> _buildAndSharePdf({
    required String title,
    required String fileName,
    required Future<Uint8List> Function() generate,
  }) async {
    // Usamos una key para poder cerrar el diálogo de forma segura.
    final dialogContext = ValueNotifier<BuildContext?>(null);

    // Mostrar loading
    if (!mounted) return;
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext.value = ctx;
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generando reporte de $title…',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ));

    // Esperar un frame para que el diálogo se registre
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final bytes = await generate();

      // Cerrar loading
      _dismissDialog(dialogContext.value);

      // Abrir vista previa para imprimir / guardar
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: fileName,
      );
    } catch (e) {
      // Cerrar loading si sigue abierto
      _dismissDialog(dialogContext.value);
      _snack('Error al generar PDF: $e', isError: true);
    }
  }

  void _dismissDialog(BuildContext? dialogCtx) {
    if (dialogCtx != null && dialogCtx.mounted) {
      Navigator.of(dialogCtx).pop();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.primary5 : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET auxiliar para las opciones del bottom sheet PDF
// ─────────────────────────────────────────────────────────────────────────────

class _PdfOptionTile extends StatelessWidget {
  const _PdfOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.dark2 : AppColors.secondary50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary5.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.primary5, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.dark0,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.dark4 : AppColors.secondary500,
          ),
        ),
        trailing: Icon(
          Icons.picture_as_pdf_rounded,
          color: AppColors.primary5,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — Dashboard (A1)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(evalStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorRetry(
        error: e,
        onRetry: () => ref.read(evalStatsProvider.notifier).refresh(),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () => ref.read(evalStatsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCards(stats: stats, isDark: isDark),
            const SizedBox(height: 16),
            _ConsistencyCard(stats: stats, isDark: isDark),
            const SizedBox(height: 16),
            _GroupCompareCard(
              miPromedio:    stats.comparacionGrupo.miPromedio,
              grupoPromedio: stats.comparacionGrupo.promedioGrupo,
              diferencia:    stats.comparacionGrupo.diferencia,
              interpretacion:stats.comparacionGrupo.interpretacion,
              isDark: isDark,
            ),
            if (stats.hardestStep != null) ...[
              const SizedBox(height: 16),
              _HardestStepCard(step: stats.hardestStep!, isDark: isDark),
            ],
            if (stats.lastEvaluation != null) ...[
              const SizedBox(height: 16),
              _LastEvalCard(eval: stats.lastEvaluation!, isDark: isDark),
            ],
            if (stats.progress.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProgressChart(points: stats.progress, isDark: isDark),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats, required this.isDark});
  final EvalStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top row: promedio + mejor
            Row(
              children: [
                _BigStat(
                  label: 'Mi promedio',
                  value: '${stats.averageScore.toStringAsFixed(1)}%',
                  color: _scoreColor(stats.averageScore),
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _BigStat(
                  label: 'Mejor puntaje',
                  value: '${stats.bestScore.toStringAsFixed(1)}%',
                  color: AppColors.success500,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Bottom row: intentos chips
            Row(
              children: [
                _SmallChip(
                  label: 'Total',
                  value: '${stats.totalAttempts}',
                  icon: Icons.repeat_rounded,
                  color: AppColors.info500,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _SmallChip(
                  label: 'Aprobados',
                  value: '${stats.approved}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success500,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _SmallChip(
                  label: 'Fallados',
                  value: '${stats.failed}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.primary5,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _SmallChip(
                  label: 'Aprobación',
                  value: '${stats.passRate.toStringAsFixed(0)}%',
                  icon: Icons.percent_rounded,
                  color: AppColors.accent400,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v >= 75) return AppColors.success500;
    if (v >= 60) return AppColors.accent400;
    return AppColors.primary5;
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.stats, required this.isDark});
  final EvalStats stats;
  final bool isDark;

  Color _nivColor(String n) {
    switch (n) {
      case 'alta':   return AppColors.success500;
      case 'baja':   return AppColors.primary5;
      default:       return AppColors.accent400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final col = _nivColor(stats.nivelConsistencia);

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.multiline_chart_rounded, color: AppColors.info500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consistencia: ${stats.nivelConsistencia}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.interpretacionConsistencia,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondary300
                              : AppColors.secondary500,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: col.withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: col),
              ),
              child: Text(
                stats.nivelConsistencia,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: col,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCompareCard extends StatelessWidget {
  const _GroupCompareCard({
    required this.miPromedio,
    required this.grupoPromedio,
    required this.diferencia,
    required this.interpretacion,
    required this.isDark,
  });
  final double miPromedio;
  final double grupoPromedio;
  final double diferencia;
  final String interpretacion;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? AppColors.cardDark : AppColors.white;
    final difColor = diferencia > 0
        ? AppColors.success500
        : diferencia < 0
            ? AppColors.primary5
            : AppColors.secondary400;
    final difIcon = diferencia > 0
        ? Icons.arrow_upward_rounded
        : diferencia < 0
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _CompareItem(
                    label: 'Mi promedio',
                    value: '${miPromedio.toStringAsFixed(1)}%',
                    isDark: isDark),
                Expanded(
                  child: Column(
                    children: [
                      Icon(difIcon, color: difColor, size: 28),
                      Text(
                        '${diferencia >= 0 ? "+" : ""}${diferencia.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: difColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                _CompareItem(
                    label: 'Grupo',
                    value: '${grupoPromedio.toStringAsFixed(1)}%',
                    isDark: isDark),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              interpretacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary300
                        : AppColors.secondary500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HardestStepCard extends StatelessWidget {
  const _HardestStepCard({required this.step, required this.isDark});
  final HardestStep step;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary5.withAlpha(isDark ? 40 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.primary5, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punto débil a mejorar',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.secondary400
                              : AppColors.secondary500,
                        ),
                  ),
                  Text(
                    'Paso ${step.stepNumber}: ${step.stepName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${step.avgScore.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary5,
                      ),
                ),
                Text(
                  '${step.attempts} intentos',
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

class _LastEvalCard extends StatelessWidget {
  const _LastEvalCard({required this.eval, required this.isDark});
  final LastEvaluation eval;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg     = isDark ? AppColors.cardDark : AppColors.white;
    final statusColor = eval.status == 'aprobado'
        ? AppColors.success500
        : AppColors.primary5;

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded,
                color: AppColors.info500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Último intento',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.secondary400
                              : AppColors.secondary500,
                        ),
                  ),
                  Text(
                    '${eval.stepsCompleted} pasos completados',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${eval.generalScore.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    eval.status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
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

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.points, required this.isDark});
  final List<ProgressPoint> points;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final maxScore = points.fold(0.0, (m, p) => p.generalScore > m ? p.generalScore : m);
    final effectiveMax = maxScore > 0 ? (maxScore > 100 ? maxScore : 100.0) : 100.0;

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso por intento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.secondary300
                        : AppColors.secondary600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Eje Y ─────────────────────────────────────────────────
                  SizedBox(
                    width: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${effectiveMax.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.secondary500
                                    : AppColors.secondary400,
                              ),
                        ),
                        Text(
                          '${(effectiveMax / 2).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.secondary500
                                    : AppColors.secondary400,
                              ),
                        ),
                        Text(
                          '0%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.secondary500
                                    : AppColors.secondary400,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // ── Gráfico ───────────────────────────────────────────────
                  Expanded(
                    child: _SimpleLineChart(
                      points: points,
                      maxY: effectiveMax,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Eje X: margen izquierdo equivalente al ancho del eje Y ──────
            Row(
              children: [
                const SizedBox(width: 42), // alinea con el inicio del gráfico
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: points
                        .asMap()
                        .entries
                        .map((e) => Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${e.key + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.secondary500
                                            : AppColors.secondary400,
                                      ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Número de intento',
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

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart(
      {required this.points, required this.maxY, required this.isDark});
  final List<ProgressPoint> points;
  final double maxY;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        scores: points.map((p) => p.generalScore).toList(),
        maxY:   maxY,
        lineColor: AppColors.primary5,
        dotColor:  AppColors.primary5,
        gridColor: isDark
            ? AppColors.secondary700
            : AppColors.secondary100,
      ),
      size: const Size(double.infinity, 100),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.scores,
    required this.maxY,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
  });

  final List<double> scores;
  final double maxY;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Horizontal grid lines at 0%, 50%, 100%
    for (final pct in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - pct);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (scores.length < 2) {
      // Single point — just draw a dot
      final x = size.width / 2;
      final y = size.height * (1 - scores.first / maxY);
      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      return;
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = dotColor;

    final step = size.width / (scores.length - 1);

    Offset? prev;
    for (int i = 0; i < scores.length; i++) {
      final x = i * step;
      final y = size.height * (1 - (scores[i] / maxY).clamp(0.0, 1.0));
      final current = Offset(x, y);
      if (prev != null) {
        canvas.drawLine(prev, current, linePaint);
      }
      canvas.drawCircle(current, 4, dotPaint);
      prev = current;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Análisis (A2)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorRetry(
        error: e,
        onRetry: () => ref.read(analyticsProvider.notifier).refresh(),
      ),
      data: (analytics) {
        if (analytics == null) {
          return const _EmptyAnalytics();
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(analyticsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PersonalStatsCard(stats: analytics.personalStats, isDark: isDark),
              const SizedBox(height: 16),
              _GroupPositionCard(cg: analytics.comparacionGrupo, isDark: isDark),
              const SizedBox(height: 16),
              _TendencyCard(tendency: analytics.tendencia, isDark: isDark),
              const SizedBox(height: 16),
              _StrengthsWeaknessesCard(
                fortalezas: analytics.fortalezas,
                debilidades: analytics.debilidades,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary.withAlpha(80)),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes evaluaciones registradas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Completa tu primer entrenamiento EPP para ver tu análisis detallado aquí.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary400,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalStatsCard extends StatelessWidget {
  const _PersonalStatsCard({required this.stats, required this.isDark});
  final PersonalStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(text: 'Mis estadísticas', isDark: isDark),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    _BigStat(
                      label: 'Promedio',
                      value: '${stats.promedio.toStringAsFixed(1)}%',
                      color: _scoreColor(stats.promedio),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _BigStat(
                      label: 'Mejor',
                      value: '${stats.mejorPuntaje.toStringAsFixed(1)}%',
                      color: AppColors.success500,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    _BigStat(
                      label: 'Intentos',
                      value: '${stats.totalIntentos}',
                      color: AppColors.info500,
                      isDark: isDark,
                      flex: 2,
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stats.interpretacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary300
                        : AppColors.secondary500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v >= 75) return AppColors.success500;
    if (v >= 60) return AppColors.accent400;
    return AppColors.primary5;
  }
}

class _GroupPositionCard extends StatelessWidget {
  const _GroupPositionCard({required this.cg, required this.isDark});
  final AnalyticsGroupComparison cg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionLabel(text: 'Posición en el grupo', isDark: isDark),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info500.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.info500.withAlpha(100)),
                  ),
                  child: Text(
                    cg.posicionEstimada,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.info500,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GroupCompareCard(
              miPromedio:    cg.miPromedio,
              grupoPromedio: cg.promedioGrupo,
              diferencia:    cg.diferencia,
              interpretacion:'',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 16, color: AppColors.accent400),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Mejor del grupo: ${cg.mejorDelGrupo.toStringAsFixed(1)}%  ·  '
                    'Para top 10%: ${cg.paraTop10.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent500,
                        ),
                    overflow: TextOverflow.ellipsis,
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

class _TendencyCard extends StatelessWidget {
  const _TendencyCard({required this.tendency, required this.isDark});
  final Tendency tendency;
  final bool isDark;

  Color _tendColor(String t) {
    switch (t) {
      case 'positiva': return AppColors.success500;
      case 'negativa': return AppColors.primary5;
      default:         return AppColors.secondary400;
    }
  }

  IconData _tendIcon(String t) {
    switch (t) {
      case 'positiva': return Icons.trending_up_rounded;
      case 'negativa': return Icons.trending_down_rounded;
      default:         return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final col    = _tendColor(tendency.tipo);

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: col.withAlpha(isDark ? 40 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(_tendIcon(tendency.tipo), color: col),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tendency.interpretacion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondary200
                              : AppColors.secondary600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mejora acumulada: +${tendency.mejorTotal.toStringAsFixed(1)} pts  ·  '
                    '${tendency.velocidadMejora.toStringAsFixed(1)} pts/intento',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

class _StrengthsWeaknessesCard extends StatelessWidget {
  const _StrengthsWeaknessesCard({
    required this.fortalezas,
    required this.debilidades,
    required this.isDark,
  });
  final List<Strength> fortalezas;
  final List<Weakness> debilidades;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;

    return Card(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fortalezas.isNotEmpty) ...[
              _SectionLabel(text: 'Fortalezas', isDark: isDark),
              const SizedBox(height: 12),
              ...fortalezas.map((s) => _StrengthRow(s: s, isDark: isDark)),
              const SizedBox(height: 16),
            ],
            if (debilidades.isNotEmpty) ...[
              _SectionLabel(text: 'Áreas a mejorar', isDark: isDark),
              const SizedBox(height: 12),
              ...debilidades.map((w) => _WeaknessRow(w: w, isDark: isDark)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.s, required this.isDark});
  final Strength s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            'Paso ${s.paso}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              s.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < s.estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                size: 14,
                color: i < s.estrellas
                    ? const Color(0xFFFFD700)
                    : AppColors.secondary300,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${s.promedio.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.success500,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeaknessRow extends StatelessWidget {
  const _WeaknessRow({required this.w, required this.isDark});
  final Weakness w;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary5.withAlpha(isDark ? 30 : 12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary5.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Paso ${w.paso}: ${w.nombre}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${w.promedio.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary5,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            w.recomendacion,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.secondary300 : AppColors.secondary600,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Historial (A3 paginado)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 100) {
      ref.read(evalHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(evalHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorRetry(
        error: e,
        onRetry: () => ref.read(evalHistoryProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.isEmpty) {
          return const Center(
            child: Text('No tienes evaluaciones registradas aún.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(evalHistoryProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _EvalSummaryCard(
                eval: state.items[i],
                isDark: widget.isDark,
              );
            },
          ),
        );
      },
    );
  }
}

class _EvalSummaryCard extends StatelessWidget {
  const _EvalSummaryCard({required this.eval, required this.isDark});
  final EvaluationSummary eval;
  final bool isDark;

  Color _statusColor(String s) {
    switch (s) {
      case 'aprobado':   return AppColors.success500;
      case 'reprobado':  return AppColors.primary5;
      default:           return AppColors.accent400;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'aprobado':   return Icons.check_circle_rounded;
      case 'reprobado':  return Icons.cancel_rounded;
      default:           return Icons.hourglass_bottom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.cardDark : AppColors.white;
    final col     = _statusColor(eval.status);
    final date    = '${eval.createdAt.day.toString().padLeft(2, '0')}/'
                    '${eval.createdAt.month.toString().padLeft(2, '0')}/'
                    '${eval.createdAt.year}';

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: col.withAlpha(60)),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          RouteNames.aprendizEvalDetail,
          extra: {'evalId': eval.id},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(_statusIcon(eval.status), color: col, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluación #${eval.id}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date · ${eval.stepsCompleted}/${eval.totalSteps} pasos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.secondary400
                                : AppColors.secondary500,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${eval.generalScore.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: col,
                        ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondary300, size: 18),
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
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.error, required this.onRetry});
  final Object error;
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
              'Error al cargar los datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary400,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.isDark});
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

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.flex = 1,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary400
                        : AppColors.secondary500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 28 : 14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary400
                        : AppColors.secondary500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareItem extends StatelessWidget {
  const _CompareItem({
    required this.label,
    required this.value,
    required this.isDark,
  });
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
