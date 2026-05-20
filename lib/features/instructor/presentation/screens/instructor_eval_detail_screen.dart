import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../domain/entities/instructor_comment.dart';
import '../providers/evaluations_notifier.dart';

class InstructorEvalDetailScreen extends ConsumerWidget {
  const InstructorEvalDetailScreen({super.key, required this.evalId});
  final int evalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final commentsAsync = ref.watch(commentsNotifierProvider(evalId));
    final detailAsync   = ref.watch(instructorEvalDetailProvider(evalId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Evaluación #$evalId',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider: false,
      ),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar: $e'),
        ),
        data: (state) => Column(
          children: [
            // ── Panel de revisión (badge + botón) ─────────────────────────
            detailAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (e, st) => const SizedBox.shrink(),
              data: (detail) => _ReviewBanner(
                evalId:   evalId,
                reviewed: detail.reviewed,
                isDark:   isDark,
              ),
            ),

            // ── Lista de comentarios ───────────────────────────────────────
            Expanded(
              child: state.comments.isEmpty
                  ? _EmptyComments(isDark: isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: state.comments.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _CommentTile(
                        comment:  state.comments[i],
                        isDark:   isDark,
                        onDelete: () => ref
                            .read(commentsNotifierProvider(evalId).notifier)
                            .deleteComment(state.comments[i].id),
                      ),
                    ),
            ),

            // ── Error inline ───────────────────────────────────────────────
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  state.errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.primary5),
                ),
              ),

            // ── Formulario para agregar comentario ────────────────────────
            _AddCommentForm(
              evalId:     evalId,
              isDark:     isDark,
              submitting: state.submitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner de estado de revisión + botón "Revisar evaluación"
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({
    required this.evalId,
    required this.reviewed,
    required this.isDark,
  });

  final int  evalId;
  final bool reviewed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor  = reviewed
        ? AppColors.success500.withAlpha(isDark ? 30 : 15)
        : AppColors.accent400.withAlpha(isDark ? 30 : 15);
    final bdColor  = reviewed
        ? AppColors.success500.withAlpha(80)
        : AppColors.accent400.withAlpha(80);
    final icon     = reviewed
        ? Icons.verified_rounded
        : Icons.pending_outlined;
    final iconCol  = reviewed ? AppColors.success500 : AppColors.accent400;
    final label    = reviewed ? 'Revisado' : 'Pendiente de revisión';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconCol),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: iconCol,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push<bool>(
              RouteNames.instructorEvalReview,
              extra: {'evalId': evalId},
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: Text(reviewed ? 'Editar revisión' : 'Revisar'),
            style: TextButton.styleFrom(
              foregroundColor: iconCol,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario para añadir comentario
// ─────────────────────────────────────────────────────────────────────────────

class _AddCommentForm extends ConsumerStatefulWidget {
  const _AddCommentForm({
    required this.evalId,
    required this.isDark,
    required this.submitting,
  });

  final int  evalId;
  final bool isDark;
  final bool submitting;

  @override
  ConsumerState<_AddCommentForm> createState() => _AddCommentFormState();
}

class _AddCommentFormState extends ConsumerState<_AddCommentForm> {
  final _controller  = TextEditingController();
  String _type       = 'observacion';
  int?   _stepNumber;

  static const _types = [
    ('observacion',   'Observación',   Icons.visibility_outlined),
    ('correcion',     'Corrección',    Icons.edit_outlined),
    ('felicitacion',  'Felicitación',  Icons.thumb_up_outlined),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < 5) return;
    await ref
        .read(commentsNotifierProvider(widget.evalId).notifier)
        .addComment(
          comment:    text,
          type:       _type,
          stepNumber: _stepNumber,
        );
    _controller.clear();
    setState(() => _stepNumber = null);
  }

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? AppColors.dark1 : AppColors.white;
    final border = widget.isDark
        ? AppColors.secondary700
        : AppColors.secondary200;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Selector de tipo ─────────────────────────────────────────────
          AppScrollBody(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _types.map((t) {
                final (value, label, icon) = t;
                final selected = _type == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: selected
                          ? AppColors.white
                          : (widget.isDark
                              ? AppColors.secondary300
                              : AppColors.secondary600),
                    ),
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = value),
                    selectedColor: AppColors.primary5,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.white
                          : (widget.isDark
                              ? AppColors.secondary300
                              : AppColors.secondary700),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary5
                          : (widget.isDark
                              ? AppColors.secondary600
                              : AppColors.secondary300),
                    ),
                    backgroundColor:
                        widget.isDark ? AppColors.dark2 : AppColors.secondary50,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Selector de paso (opcional) ──────────────────────────────────
          Row(
            children: [
              Text(
                'Paso (opcional):',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.isDark
                          ? AppColors.secondary400
                          : AppColors.secondary500,
                    ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: _stepNumber,
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
                onChanged: (v) => setState(() => _stepNumber = v),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Campo de texto + botón enviar ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller:      _controller,
                  maxLines:        3,
                  minLines:        1,
                  maxLength:       1000,
                  decoration: InputDecoration(
                    hintText:    'Escribe tu comentario...',
                    counterText: '',
                    filled:      true,
                    fillColor:   widget.isDark
                        ? AppColors.dark2
                        : AppColors.secondary50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:   BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:   BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary5, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 10),
              widget.submitting
                  ? const SizedBox(
                      width:  44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width:  22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary5,
                        minimumSize: const Size(44, 44),
                        padding:     EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de comentario con swipe para eliminar
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.onDelete,
  });

  final InstructorComment comment;
  final bool              isDark;
  final VoidCallback      onDelete;

  Color    _typeColor(String type) {
    switch (type) {
      case 'correcion':    return AppColors.accent400;
      case 'felicitacion': return AppColors.success500;
      default:             return AppColors.info500;
    }
  }

  String   _typeLabel(String type) {
    switch (type) {
      case 'correcion':    return 'Corrección';
      case 'felicitacion': return 'Felicitación';
      default:             return 'Observación';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'correcion':    return Icons.edit_outlined;
      case 'felicitacion': return Icons.thumb_up_outlined;
      default:             return Icons.visibility_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col    = _typeColor(comment.type);
    final cardBg = isDark ? AppColors.cardDark : AppColors.white;
    final d      = comment.createdAt;
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final dateStr =
        '${d.day.toString().padLeft(2, '0')} ${months[d.month]} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(comment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.primary5.withAlpha(200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar comentario'),
            content:
                const Text('¿Seguro que deseas eliminar este comentario?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary5),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.secondary700 : AppColors.secondary200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo + paso + fecha
            Row(
              children: [
                Icon(_typeIcon(comment.type), size: 14, color: col),
                const SizedBox(width: 5),
                Text(
                  _typeLabel(comment.type),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: col,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (comment.stepNumber != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: col.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Paso ${comment.stepNumber}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: col,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.secondary500
                            : AppColors.secondary400,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Texto del comentario
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
// Estado vacío
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyComments extends StatelessWidget {
  const _EmptyComments({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: isDark ? AppColors.secondary600 : AppColors.secondary300,
          ),
          const SizedBox(height: 14),
          Text(
            'Sin comentarios todavía',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondary400
                      : AppColors.secondary500,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega el primero desde el formulario de abajo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.secondary500
                      : AppColors.secondary400,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
