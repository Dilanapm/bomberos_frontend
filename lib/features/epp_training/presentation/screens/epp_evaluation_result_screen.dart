import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../providers/aprendiz_provider.dart';
import '../providers/epp_training_provider.dart';

Color _scoreColor(double pct) {
  if (pct >= 75) return AppColors.success500;
  if (pct >= 50) return AppColors.accent400;
  return AppColors.primary5;
}

String _scoreLabel(double pct) {
  if (pct >= 75) return 'Correcto';
  if (pct >= 50) return 'Irregular';
  return 'No realizado';
}

String _overallHeadline(double pct) {
  if (pct >= 75) return 'Excelente trabajo';
  if (pct >= 50) return 'Trabajo irregular';
  return 'Requiere mejora';
}

String _stepDisplayName(String key) {
  switch (key) {
    case 'pantalon_ignifugo':
      return 'Pantalón Ignífugo';
    case 'esclavina':
      return 'Esclavina';
    case 'chaqueta_ignifuga':
      return 'Chaqueta Ignífuga';
    case 'casco':
      return 'Casco';
    case 'guantes':
      return 'Guantes';
    case 'postura_final':
      return 'Postura Final';
    default:
      return key.replaceAll('_', ' ');
  }
}

class EppEvaluationResultArgs {
  const EppEvaluationResultArgs({
    required this.precision,
    required this.totalVentanas,
    required this.correctos,
    required this.incorrectos,
    required this.scores,
    required this.laravelPayload,
  });

  /// Precisión general (0..1).
  final double precision;

  final int totalVentanas;

  final List<String> correctos;
  final List<String> incorrectos;

  /// Scores por paso (0..1 típicamente). Key en snake_case.
  final Map<String, dynamic> scores;

  /// Payload listo para enviar a Laravel.
  final Map<String, dynamic> laravelPayload;
}

class EppEvaluationResultScreen extends ConsumerStatefulWidget {
  const EppEvaluationResultScreen({
    super.key,
    required this.args,
  });

  final EppEvaluationResultArgs args;

  @override
  ConsumerState<EppEvaluationResultScreen> createState() =>
      _EppEvaluationResultScreenState();
}

class _EppEvaluationResultScreenState
    extends ConsumerState<EppEvaluationResultScreen> {
  bool _isSaving = false;
  bool _isInstructor = false;
  int? _savedEvalId;

  final _commentCtrl = TextEditingController();
  String _commentType = 'observacion';
  int? _stepNumber;
  String? _commentError;

  static const _commentTypes = [
    ('observacion', 'Observación', Icons.visibility_outlined),
    ('correcion', 'Corrección', Icons.edit_outlined),
    ('felicitacion', 'Felicitación', Icons.thumb_up_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final storage = ref.read(secureStorageProvider);
    final role = await storage.readUserRole() ?? 'aprendiz';
    if (!mounted) return;
    setState(() => _isInstructor = role == 'instructor');
  }

  int? _extractEvalId(dynamic body) {
    int? asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final id = asInt(data['id']) ??
            asInt(data['evaluation_id']) ??
            asInt(data['eval_id']);
        if (id != null) return id;

        final nested = data['evaluation'] ?? data['eval'];
        if (nested is Map<String, dynamic>) {
          final nid = asInt(nested['id']) ??
              asInt(nested['evaluation_id']) ??
              asInt(nested['eval_id']);
          if (nid != null) return nid;
        }
      } else {
        final id = asInt(data);
        if (id != null) return id;
      }

      final id = asInt(body['id']) ??
          asInt(body['evaluation_id']) ??
          asInt(body['eval_id']);
      if (id != null) return id;
    }
    return null;
  }

  Future<({bool ok, int? evalId})> _saveEvaluation(
      Map<String, dynamic> laravelPayload) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final role = await storage.readUserRole() ?? 'aprendiz';
      final isInstructor = role == 'instructor';

      final url = isInstructor ? '/instructor/evaluations' : '/evaluations';

      final payload = Map<String, dynamic>.from(laravelPayload);

      if (isInstructor) {
        final aprendiz = ref.read(selectedAprendizProvider);
        if (aprendiz != null) payload['user_id'] = aprendiz.id;
      }

      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post(url, data: payload);

      final ok = response.statusCode == 200 || response.statusCode == 201;
      return (ok: ok, evalId: ok ? _extractEvalId(response.data) : null);
    } catch (_) {
      return (ok: false, evalId: null);
    }
  }

  Future<bool> _saveInstructorComment({
    required int evalId,
    required String comment,
    required String type,
    int? stepNumber,
  }) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final body = <String, dynamic>{
        'comment': comment,
        'type': type,
        'step_number': stepNumber,
      }..removeWhere((_, v) => v == null);
      final res = await dio.post(
        ApiEndpoints.instructorEvalComments(evalId),
        data: body,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onRepeat() async {
    ref.read(eppTrainingProvider.notifier).clearHistory();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    final commentText = _commentCtrl.text.trim();
    if (_isInstructor && commentText.isNotEmpty && commentText.length < 5) {
      setState(() {
        _commentError = 'El comentario debe tener al menos 5 caracteres.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _commentError = null;
    });

    var evalId = _savedEvalId;
    var evalOk = true;
    if (evalId == null) {
      final res = await _saveEvaluation(widget.args.laravelPayload);
      evalOk = res.ok;
      evalId = res.evalId;
      if (evalOk) _savedEvalId = evalId;
    }

    if (!mounted) return;

    if (!evalOk) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al guardar la evaluación'),
          backgroundColor: AppColors.primary5,
        ),
      );
      return;
    }

    // Guardar comentario (solo instructor y si escribió algo)
    if (_isInstructor && commentText.isNotEmpty) {
      if (evalId == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Evaluación guardada, pero no se pudo adjuntar el comentario.'),
            backgroundColor: AppColors.accent400,
          ),
        );
        return;
      }

      final commentOk = await _saveInstructorComment(
        evalId: evalId,
        comment: commentText,
        type: _commentType,
        stepNumber: _stepNumber,
      );

      if (!mounted) return;

      if (!commentOk) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Evaluación guardada, pero falló el comentario. Reintenta.'),
            backgroundColor: AppColors.accent400,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = false);
    ref.read(eppTrainingProvider.notifier).clearHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (_isInstructor && commentText.isNotEmpty)
              ? '✅ Evaluación y comentario guardados'
              : '✅ Evaluación guardada correctamente',
        ),
        backgroundColor: AppColors.success500,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.dark0 : AppColors.secondary50;

    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(eppTrainingProvider.notifier).clearHistory();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppAppBar(
          title: 'Resultado de Evaluación',
          backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
          foregroundColor: AppColors.white,
          showDivider: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _isSaving
                ? null
                : () {
                    ref.read(eppTrainingProvider.notifier).clearHistory();
                    Navigator.of(context).pop();
                  },
          ),
        ),
        body: _isInstructor
            ? Column(
                children: [
                  Expanded(
                    child: _Body(
                      args: widget.args,
                      isDark: isDark,
                      isSaving: _isSaving,
                      onRepeat: _onRepeat,
                      onSave: _onSave,
                      includeActions: false,
                    ),
                  ),
                  _InstructorCommentFooter(
                    isDark: isDark,
                    isSaving: _isSaving,
                    controller: _commentCtrl,
                    commentError: _commentError,
                    commentType: _commentType,
                    stepNumber: _stepNumber,
                    onTypeSelected: (v) => setState(() => _commentType = v),
                    onStepChanged: (v) => setState(() => _stepNumber = v),
                    onRepeat: _onRepeat,
                    onSave: _onSave,
                  ),
                ],
              )
            : _Body(
                args: widget.args,
                isDark: isDark,
                isSaving: _isSaving,
                onRepeat: _onRepeat,
                onSave: _onSave,
                includeActions: true,
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.args,
    required this.isDark,
    required this.isSaving,
    required this.onRepeat,
    required this.onSave,
    required this.includeActions,
  });

  final EppEvaluationResultArgs args;
  final bool isDark;
  final bool isSaving;
  final VoidCallback onRepeat;
  final VoidCallback onSave;
  final bool includeActions;

  @override
  Widget build(BuildContext context) {
    final pct = (args.precision * 100).clamp(0.0, 100.0);

    final stepScores = _buildStepScores();
    final keyPoints = stepScores.where((s) => s.percent < 75).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(
          percent: pct,
          totalVentanas: args.totalVentanas,
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        if (stepScores.isNotEmpty) ...[
          _HeaderRow(
            title: 'Hallazgos de la sesión',
            countLabel: '${keyPoints == 0 ? stepScores.length : keyPoints} PUNTOS CLAVE',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          ...stepScores.map((s) => _EppStepCard(step: s, isDark: isDark)),
          const SizedBox(height: 20),
        ],

        if (includeActions) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onRepeat,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Repetir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(isSaving ? 'Guardando…' : 'Guardar Reporte'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary5,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  List<_EppStepScore> _buildStepScores() {
    if (args.scores.isNotEmpty) {
      final items = <_EppStepScore>[];
      for (final entry in args.scores.entries) {
        final raw = entry.value;
        final rawNum = raw is num ? raw.toDouble() : 0.0;
        final percent = rawNum <= 1.0 ? rawNum * 100 : rawNum;
        items.add(
          _EppStepScore(
            key: entry.key,
            name: _stepDisplayName(entry.key),
            percent: percent.clamp(0.0, 100.0),
          ),
        );
      }
      items.sort((a, b) => a.percent.compareTo(b.percent));
      return items;
    }

    // Fallback: si no hay scores, usar correctos/incorrectos.
    final items = <_EppStepScore>[];
    for (final s in args.correctos) {
      items.add(_EppStepScore(key: s, name: _stepDisplayName(s), percent: 100));
    }
    for (final s in args.incorrectos) {
      items.add(_EppStepScore(key: s, name: _stepDisplayName(s), percent: 0));
    }
    items.sort((a, b) => a.percent.compareTo(b.percent));
    return items;
  }
}

class _InstructorCommentFooter extends StatelessWidget {
  const _InstructorCommentFooter({
    required this.isDark,
    required this.isSaving,
    required this.controller,
    required this.commentError,
    required this.commentType,
    required this.stepNumber,
    required this.onTypeSelected,
    required this.onStepChanged,
    required this.onRepeat,
    required this.onSave,
  });

  final bool isDark;
  final bool isSaving;
  final TextEditingController controller;
  final String? commentError;
  final String commentType;
  final int? stepNumber;
  final ValueChanged<String> onTypeSelected;
  final ValueChanged<int?> onStepChanged;
  final VoidCallback onRepeat;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.dark1 : AppColors.white;
    final border = isDark ? AppColors.secondary700 : AppColors.secondary200;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Deja tu observación',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.secondary50 : AppColors.secondary900,
                ),
          ),
          const SizedBox(height: 10),

          // Selector de tipo
          AppScrollBody(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _EppEvaluationResultScreenState._commentTypes.map((t) {
                final (value, label, icon) = t;
                final selected = commentType == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: selected
                          ? AppColors.white
                          : (isDark
                              ? AppColors.secondary300
                              : AppColors.secondary600),
                    ),
                    label: Text(label),
                    selected: selected,
                    onSelected: isSaving ? null : (_) => onTypeSelected(value),
                    selectedColor: AppColors.primary5,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.white
                          : (isDark
                              ? AppColors.secondary300
                              : AppColors.secondary700),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary5
                          : (isDark ? AppColors.secondary600 : AppColors.secondary300),
                    ),
                    backgroundColor: isDark ? AppColors.dark2 : AppColors.secondary50,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Selector de paso (opcional)
          Row(
            children: [
              Text(
                'Paso (opcional):',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.secondary400 : AppColors.secondary500,
                    ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: stepNumber,
                hint: Text(
                  'General',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                underline: const SizedBox(),
                isDense: true,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'General',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  ...List.generate(
                    6,
                    (i) => DropdownMenuItem<int?>(
                      value: i + 1,
                      child: Text(
                        'Paso ${i + 1}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
                onChanged: isSaving ? null : onStepChanged,
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            enabled: !isSaving,
            maxLines: 3,
            minLines: 1,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Escribe tu comentario...',
              counterText: '',
              filled: true,
              fillColor: isDark ? AppColors.dark2 : AppColors.secondary50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary5, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            textInputAction: TextInputAction.newline,
          ),

          if (commentError != null) ...[
            const SizedBox(height: 6),
            Text(
              commentError!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.primary5),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onRepeat,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Repetir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(isSaving ? 'Guardando…' : 'Guardar Reporte'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary5,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.countLabel,
    required this.isDark,
  });

  final String title;
  final String countLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.secondary50 : AppColors.secondary900,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.dark2 : AppColors.secondary100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.secondary600 : AppColors.secondary200,
            ),
          ),
          child: Text(
            countLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.secondary300 : AppColors.secondary600,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.percent,
    required this.totalVentanas,
    required this.isDark,
  });

  final double percent;
  final int totalVentanas;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final col = _scoreColor(percent);
    final statusText = percent >= 75 ? 'APROBADO' : 'REPROBADO';
    final headline = _overallHeadline(percent);

    final points = percent.round();

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: col.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col, width: 2),
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: col,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: (percent / 100).clamp(0.0, 1.0),
                    color: col,
                    backgroundColor:
                        isDark ? AppColors.secondary600 : AppColors.secondary100,
                    strokeWidth: 12,
                  ),
                  size: const Size(220, 220),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$points',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.white : AppColors.secondary900,
                            fontSize: 56,
                          ),
                    ),
                    Text(
                      '/ 100 PUNTOS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.secondary300
                                : AppColors.secondary600,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            headline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.secondary50 : AppColors.secondary900,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        if (totalVentanas > 0)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ventanas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondary400
                            : AppColors.secondary500,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalVentanas',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.secondary200
                            : AppColors.secondary700,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EppStepScore {
  const _EppStepScore({
    required this.key,
    required this.name,
    required this.percent,
  });

  final String key;
  final String name;
  final double percent;
}

class _EppStepCard extends StatelessWidget {
  const _EppStepCard({required this.step, required this.isDark});

  final _EppStepScore step;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = step.percent;
    final col = _scoreColor(pct);
    final icon = pct >= 75
        ? Icons.check_circle_rounded
        : pct >= 50
            ? Icons.warning_rounded
            : Icons.cancel_rounded;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: col, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.secondary50 : AppColors.secondary900,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _scoreLabel(pct),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.secondary400
                              : AppColors.secondary500,
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: col,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (progress.clamp(0.0, 1.0)) * 2 * math.pi,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
