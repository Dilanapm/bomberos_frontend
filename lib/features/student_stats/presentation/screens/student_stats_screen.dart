import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../domain/entities/group_summary.dart';
import '../../domain/entities/need_help_data.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/entities/step_performance.dart';
import '../providers/stats_notifier.dart';

class StudentStatsScreen extends ConsumerStatefulWidget {
  const StudentStatsScreen({super.key});

  @override
  ConsumerState<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends ConsumerState<StudentStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(statsNotifierProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(statsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Estadísticas del Grupo',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.primary1,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded),    text: 'Resumen'),
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Ranking'),
            Tab(icon: Icon(Icons.warning_amber_rounded),text: 'Alertas'),
            Tab(icon: Icon(Icons.bar_chart_rounded),    text: 'Pasos'),
          ],
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(error: err, onRetry: _refresh),
        data: (bundle) => TabBarView(
          controller: _tabs,
          children: [
            _DashboardTab(summary: bundle.groupSummary, isDark: isDark),
            _RankingTab(entries: bundle.ranking, isDark: isDark, onRefresh: _refresh),
            _AlertsTab(data: bundle.needHelp, isDark: isDark, onRefresh: _refresh),
            _StepsTab(steps: bundle.steps, isDark: isDark, onRefresh: _refresh),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
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
              'No se pudieron cargar las estadísticas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondary400),
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.summary, required this.isDark});
  final GroupSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},   // handled by AppBar refresh button
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Resumen del Grupo', isDark: isDark),
          const SizedBox(height: 12),
          _GroupOverviewCard(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _SectionHeader(title: 'vs. Institución', isDark: isDark),
          const SizedBox(height: 12),
          _VsInstitucionCard(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Consistencia del Grupo', isDark: isDark),
          const SizedBox(height: 12),
          _ConsistencyCard(summary: summary, isDark: isDark),
        ],
      ),
    );
  }
}

class _GroupOverviewCard extends StatelessWidget {
  const _GroupOverviewCard({required this.summary, required this.isDark});
  final GroupSummary summary;
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
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: '${summary.totalAprendices}',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.info500,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Promedio',
                  value: '${summary.promedioGrupo.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: _promedioColor(summary.promedioGrupo),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Aprobación',
                  value: '${summary.tasaAprobacion.toStringAsFixed(1)}%',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success500,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                if (summary.mejorAprendiz != null) ...[
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFFD700),
                      label: 'Mejor del grupo',
                      value:
                          '${summary.mejorAprendiz!.name} · '
                          '${summary.mejorAprendiz!.promedio.toStringAsFixed(1)}%',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _InfoRow(
                    icon: Icons.support_agent_rounded,
                    color: AppColors.accent400,
                    label: 'Necesitan apoyo',
                    value: '${summary.necesitanApoyo} aprendiz(ces)',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _promedioColor(double v) {
    if (v >= 75) return AppColors.success500;
    if (v >= 60) return AppColors.accent400;
    return AppColors.primary5;
  }
}

class _VsInstitucionCard extends StatelessWidget {
  const _VsInstitucionCard({required this.summary, required this.isDark});
  final GroupSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final dif = summary.diferencia;
    final difColor = dif > 0
        ? AppColors.success500
        : dif < 0
            ? AppColors.primary5
            : AppColors.secondary400;
    final difIcon = dif > 0
        ? Icons.arrow_upward_rounded
        : dif < 0
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

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
                _CompareItem(
                  label: 'Mi grupo',
                  value: '${summary.miGrupoPromedio.toStringAsFixed(1)}%',
                  isDark: isDark,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(difIcon, color: difColor, size: 28),
                      Text(
                        '${dif >= 0 ? '+' : ''}${dif.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: difColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                _CompareItem(
                  label: 'Institución',
                  value:
                      '${summary.promedioInstitucional.toStringAsFixed(1)}%',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary.interpretacionVsInstitucion,
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
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.summary, required this.isDark});
  final GroupSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final nivelColor = _nivelColor(summary.nivelConsistencia);

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
                const Icon(Icons.multiline_chart_rounded,
                    color: AppColors.info500),
                const SizedBox(width: 8),
                Text(
                  'Desviación estándar: '
                  '${summary.desviacionEstandar.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: nivelColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: nivelColor, width: 1),
                  ),
                  child: Text(
                    summary.nivelConsistencia,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: nivelColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary.interpretacionConsistencia,
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

  Color _nivelColor(String nivel) {
    switch (nivel) {
      case 'alta':
        return AppColors.primary5;
      case 'moderada':
        return AppColors.accent400;
      default:
        return AppColors.success500;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Ranking
// ─────────────────────────────────────────────────────────────────────────────

class _RankingTab extends StatelessWidget {
  const _RankingTab(
      {required this.entries, required this.isDark, required this.onRefresh});
  final List<RankingEntry> entries;
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No hay datos de ranking disponibles.'),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: entries.length,
        itemBuilder: (ctx, i) =>
            _RankingCard(entry: entries[i], isDark: isDark),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.entry, required this.isDark});
  final RankingEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? AppColors.cardDark : AppColors.white;
    final badgeCol = _badgeColor(entry.badge);
    final trendCol = _trendColor(entry.tendencia);
    final trendIcon = _trendIcon(entry.tendencia);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Position + badge
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '#${entry.posicion}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.secondary300
                              : AppColors.secondary500,
                        ),
                  ),
                  if (entry.badge != 'sin_badge')
                    Icon(_badgeIcon(entry.badge), color: badgeCol, size: 20),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Name + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.intentos} intentos · mejor: '
                    '${entry.mejorPuntaje.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondary400
                              : AppColors.secondary500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Promedio + tendencia
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.promedio.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _promedioColor(entry.promedio),
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 14, color: trendCol),
                    const SizedBox(width: 2),
                    Text(
                      entry.tendencia,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: trendCol,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'oro':    return const Color(0xFFFFD700);
      case 'plata':  return const Color(0xFFC0C0C0);
      case 'bronce': return const Color(0xFFCD7F32);
      default:       return AppColors.secondary300;
    }
  }

  IconData _badgeIcon(String badge) {
    switch (badge) {
      case 'oro':    return Icons.workspace_premium_rounded;
      case 'plata':  return Icons.military_tech_rounded;
      case 'bronce': return Icons.emoji_events_rounded;
      default:       return Icons.star_border_rounded;
    }
  }

  Color _trendColor(String tendencia) {
    switch (tendencia) {
      case 'mejorando':   return AppColors.success500;
      case 'empeorando':  return AppColors.primary5;
      default:            return AppColors.secondary400;
    }
  }

  IconData _trendIcon(String tendencia) {
    switch (tendencia) {
      case 'mejorando':   return Icons.trending_up_rounded;
      case 'empeorando':  return Icons.trending_down_rounded;
      default:            return Icons.trending_flat_rounded;
    }
  }

  Color _promedioColor(double v) {
    if (v >= 75) return AppColors.success500;
    if (v >= 60) return AppColors.accent400;
    return AppColors.primary5;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Alertas
// ─────────────────────────────────────────────────────────────────────────────

class _AlertsTab extends StatelessWidget {
  const _AlertsTab(
      {required this.data, required this.isDark, required this.onRefresh});
  final NeedHelpData data;
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: data.total == 0
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 56, color: AppColors.success500),
                      const SizedBox(height: 16),
                      Text(
                        '¡Todos los aprendices están al día!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AlertHeader(total: data.total, isDark: isDark),
                const SizedBox(height: 12),
                ...data.aprendices.map(
                  (s) => _AlertCard(student: s, isDark: isDark),
                ),
              ],
            ),
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({required this.total, required this.isDark});
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary5.withAlpha(isDark ? 40 : 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary5.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.primary5),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$total aprendiz(ces) con promedio inferior a 65% necesitan atención.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary5,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.student, required this.isDark});
  final NeedHelpStudent student;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg      = isDark ? AppColors.cardDark : AppColors.white;
    final prioColor   = student.prioridad == 'alta'
        ? AppColors.primary5
        : AppColors.accent400;
    final prioBg      = prioColor.withAlpha(isDark ? 40 : 20);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: prioColor.withAlpha(60)),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: prioColor.withAlpha(30),
                  child: Icon(Icons.person_rounded, color: prioColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: prioBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: prioColor, width: 1),
                  ),
                  child: Text(
                    'Prioridad ${student.prioridad}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: prioColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _MiniStat(
                  label: 'Prom. general',
                  value: '${student.promedioGeneral.toStringAsFixed(1)}%',
                  color: prioColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Prom. paso prob.',
                  value: '${student.promedioPaso.toStringAsFixed(1)}%',
                  color: AppColors.accent400,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Problem
            Text(
              student.problema,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondary300
                        : AppColors.secondary600,
                  ),
            ),
            const SizedBox(height: 8),
            // Recommendation
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: AppColors.accent400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    student.recomendacion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent500,
                          fontStyle: FontStyle.italic,
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — Pasos EPP
// ─────────────────────────────────────────────────────────────────────────────

class _StepsTab extends StatelessWidget {
  const _StepsTab(
      {required this.steps, required this.isDark, required this.onRefresh});
  final List<StepPerformance> steps;
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: 'Rendimiento por Paso EPP',
            isDark: isDark,
          ),
          const SizedBox(height: 4),
          Text(
            'Promedio del grupo en cada uno de los 6 pasos del protocolo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isDark ? AppColors.secondary400 : AppColors.secondary500,
                ),
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => _StepBar(step: s, isDark: isDark)),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.isDark});
  final StepPerformance step;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? AppColors.cardDark : AppColors.white;
    final barColor = _difficultyColor(step.dificultad);
    final pct      = (step.promedioGrupo / 100).clamp(0.0, 1.0);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: barColor.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                    border: Border.all(color: barColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${step.numero}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: barColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.nombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                // Difficulty chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: barColor.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: barColor.withAlpha(120)),
                  ),
                  child: Text(
                    step.dificultad,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${step.promedioGrupo.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.secondary600
                    : AppColors.secondary100,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            if (step.problema != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColors.primary5),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      step.problema!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary5,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String dificultad) {
    switch (dificultad) {
      case 'dificil':  return AppColors.primary5;
      case 'moderado': return AppColors.accent400;
      default:         return AppColors.success500; // facil
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.secondary300 : AppColors.secondary600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.secondary400
                          : AppColors.secondary500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
