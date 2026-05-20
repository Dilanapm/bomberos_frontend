import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../aprendiz_stats/domain/entities/evaluation_detail.dart';
import '../../domain/entities/instructor_review.dart';
import '../providers/evaluations_notifier.dart';

/// Pantalla de revisión del instructor.
/// Carga el detalle de la evaluación y permite al instructor corregir
/// el veredicto de cada paso y asignar un puntaje global.
class InstructorReviewScreen extends ConsumerWidget {
  const InstructorReviewScreen({super.key, required this.evalId});
  final int evalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final detailAsync  = ref.watch(instructorEvalDetailProvider(evalId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Revisar Evaluación #$evalId',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider: false,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (detail) => _ReviewForm(
          evalId: evalId,
          detail: detail,
          isDark: isDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de revisión (StatefulWidget para manejar estado local)
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.evalId,
    required this.detail,
    required this.isDark,
  });

  final int evalId;
  final EvaluationDetail detail;
  final bool isDark;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late final TextEditingController _finalScoreCtrl;

  // Por cada paso: estado local (puede ser null = sin cambio)
  late final Map<int, String?>  _stepStatus;  // "correcto" | "incorrecto" | null
  late final Map<int, TextEditingController> _noteCtrl;

  @override
  void initState() {
    super.initState();
    // Inicializar con los valores actuales del instructor (si ya revisó)
    _stepStatus = {};
    _noteCtrl   = {};
    for (final s in widget.detail.steps) {
      _stepStatus[s.stepNumber] = s.instructorStatus;
      _noteCtrl[s.stepNumber]   = TextEditingController(
        text: s.instructorNote ?? '',
      );
    }
    _finalScoreCtrl = TextEditingController(
      text: widget.detail.instructorFinalScore != null
          ? widget.detail.instructorFinalScore!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _finalScoreCtrl.dispose();
    for (final c in _noteCtrl.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    // Construir pasos con cambios
    final steps = <InstructorReviewStep>[];
    for (final s in widget.detail.steps) {
      final n = s.stepNumber;
      final status = _stepStatus[n];
      final note   = _noteCtrl[n]?.text.trim() ?? '';
      final hasChange = status != null || note.isNotEmpty;
      if (!hasChange) continue;
      steps.add(InstructorReviewStep(
        stepNumber:       n,
        instructorStatus: status,
        instructorNote:   note.isEmpty ? null : note,
      ));
    }

    final rawScore = double.tryParse(_finalScoreCtrl.text.trim());
    final payload  = InstructorReviewPayload(
      instructorFinalScore: rawScore,
      steps: steps,
    );

    final ok = await ref
        .read(instructorReviewNotifierProvider.notifier)
        .submit(evalId: widget.evalId, payload: payload);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisión guardada correctamente'),
          backgroundColor: AppColors.success500,
        ),
      );
      Navigator.of(context).pop(true); // true = se guardó
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(instructorReviewNotifierProvider);
    final isDark      = widget.isDark;
    final steps       = widget.detail.steps;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Puntaje global del instructor ────────────────────────────────────
        _SectionLabel(text: 'PUNTAJE GLOBAL DEL INSTRUCTOR', isDark: isDark),
        const SizedBox(height: 8),
        _GlobalScoreField(
          controller: _finalScoreCtrl,
          generalScore: widget.detail.generalScore,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // ── Revisión por paso ────────────────────────────────────────────────
        _SectionLabel(text: 'REVISIÓN POR PASO', isDark: isDark),
        const SizedBox(height: 12),
        ...steps.map(
          (s) => _StepReviewCard(
            step:       s,
            isDark:     isDark,
            status:     _stepStatus[s.stepNumber],
            noteCtrl:   _noteCtrl[s.stepNumber]!,
            onStatusChanged: (v) => setState(
              () => _stepStatus[s.stepNumber] = v,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Error inline ─────────────────────────────────────────────────────
        if (reviewState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              reviewState.errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.primary5),
              textAlign: TextAlign.center,
            ),
          ),

        // ── Botón guardar ─────────────────────────────────────────────────────
        FilledButton.icon(
          onPressed: reviewState.submitting ? null : _submit,
          icon: reviewState.submitting
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(reviewState.submitting
              ? 'Guardando...'
              : 'Guardar revisión'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary5,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de puntaje global
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalScoreField extends StatelessWidget {
  const _GlobalScoreField({
    required this.controller,
    required this.generalScore,
    required this.isDark,
  });

  final TextEditingController controller;
  final double generalScore;
  final bool   isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.secondary700 : AppColors.secondary300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puntaje de la IA: ${generalScore.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.secondary400 : AppColors.secondary500,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ej: 82.0  (dejar vacío para no cambiar)',
            suffixText: '%',
            filled: true,
            fillColor: isDark ? AppColors.dark2 : AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary5, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de revisión de un paso
// ─────────────────────────────────────────────────────────────────────────────

class _StepReviewCard extends StatelessWidget {
  const _StepReviewCard({
    required this.step,
    required this.isDark,
    required this.status,
    required this.noteCtrl,
    required this.onStatusChanged,
  });

  final EvalStep step;
  final bool     isDark;
  final String?  status;
  final TextEditingController noteCtrl;
  final ValueChanged<String?> onStatusChanged;

  Color _aiStatusColor(String s) {
    switch (s) {
      case 'correcto':     return AppColors.success500;
      case 'incorrecto':   return AppColors.primary5;
      default:             return AppColors.secondary400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? AppColors.cardDark : AppColors.white;
    final border   = isDark ? AppColors.secondary700 : AppColors.secondary200;
    final subColor = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final aiCol    = _aiStatusColor(step.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número + nombre del paso
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary5.withAlpha(isDark ? 50 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Paso ${step.stepNumber}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary5,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.stepName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Veredicto de la IA
          Row(
            children: [
              Text(
                'IA:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: subColor,
                    ),
              ),
              const SizedBox(width: 6),
              Icon(
                step.status == 'correcto'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 14,
                color: aiCol,
              ),
              const SizedBox(width: 4),
              Text(
                step.status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: aiCol,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${step.scorePercent.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: subColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Toggle status del instructor
          Text(
            'Tu veredicto:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subColor,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatusChip(
                label:    'Correcto',
                icon:     Icons.check_circle_outline_rounded,
                color:    AppColors.success500,
                selected: status == 'correcto',
                onTap: () => onStatusChanged(
                  status == 'correcto' ? null : 'correcto',
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label:    'Incorrecto',
                icon:     Icons.cancel_outlined,
                color:    AppColors.primary5,
                selected: status == 'incorrecto',
                onTap: () => onStatusChanged(
                  status == 'incorrecto' ? null : 'incorrecto',
                ),
                isDark: isDark,
              ),
              if (status != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onStatusChanged(null),
                  child: Text(
                    'Quitar',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: subColor,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Nota del instructor
          TextField(
            controller: noteCtrl,
            maxLines:   3,
            minLines:   1,
            maxLength:  500,
            decoration: InputDecoration(
              hintText:    'Nota sobre este paso (opcional)...',
              counterText: '',
              filled:      true,
              fillColor:   isDark ? AppColors.dark2 : AppColors.secondary50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary5, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de selección de status
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String   label;
  final IconData icon;
  final Color    color;
  final bool     selected;
  final VoidCallback onTap;
  final bool     isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha(isDark ? 50 : 25)
              : (isDark ? AppColors.dark2 : AppColors.secondary50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : (isDark
                ? AppColors.secondary600
                : AppColors.secondary300),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? color : (isDark
                    ? AppColors.secondary400
                    : AppColors.secondary500)),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? color
                        : (isDark
                            ? AppColors.secondary400
                            : AppColors.secondary600),
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.isDark});
  final String text;
  final bool   isDark;

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
