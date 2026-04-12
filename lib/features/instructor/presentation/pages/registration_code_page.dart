import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_scroll_body.dart';
import '../../domain/entities/registration_code.dart';
import '../providers/instructor_notifier.dart';

class RegistrationCodePage extends ConsumerStatefulWidget {
  const RegistrationCodePage({super.key});

  @override
  ConsumerState<RegistrationCodePage> createState() =>
      _RegistrationCodePageState();
}

class _RegistrationCodePageState extends ConsumerState<RegistrationCodePage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refrescar datos del servidor cada vez que se abre la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instructorNotifierProvider.notifier).refresh();
    });
    // Ticker para actualizar el countdown cada segundo
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    try {
      await ref.read(instructorNotifierProvider.notifier).generateCode();
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    }
  }

  Future<void> _revoke() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title:       'Revocar código',
      message:     '¿Deseas invalidar el código activo? El aprendiz no podrá usarlo.',
      confirmText: 'Revocar',
      isDanger:    true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(instructorNotifierProvider.notifier).revokeCode();
      if (!mounted) return;
      AppToast.showSuccess(context, 'Código revocado.');
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppToast.showSuccess(context, 'Código copiado al portapapeles.');
  }

  @override
  Widget build(BuildContext context) {
    final text       = Theme.of(context).textTheme;
    final stateAsync = ref.watch(instructorNotifierProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Agregar aprendices',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: () =>
                ref.read(instructorNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, st) => _buildError(
            (e is AppException) ? e.message : e.toString()),
        data:    (s) => _buildContent(s, text),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 56, color: AppColors.primary6),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              label:     'Reintentar',
              onPressed: () =>
                  ref.read(instructorNotifierProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(InstructorState s, TextTheme text) {
    return AppScrollBody(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.code != null && s.code!.isActive)
            _buildActiveCode(s.code!, text)
          else
            _buildNoCode(text),
        ],
      ),
    );
  }

  Widget _buildNoCode(TextTheme text) {
    return Column(
      children: [
        // ── Instrucciones paso a paso ─────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary5.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.info,
                      size: 20, color: AppColors.primary5),
                  const SizedBox(width: 8),
                  Text(
                    '¿Cómo agregar aprendices?',
                    style: text.titleSmall
                        ?.copyWith(color: AppColors.primary5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Step(
                number: '1',
                text: 'Presiona "Generar código" para crear un código '
                    'único de registro.',
              ),
              const SizedBox(height: 8),
              _Step(
                number: '2',
                text: 'Comparte ese código con el aprendiz que deseas '
                    'vincular a tu grupo.',
              ),
              const SizedBox(height: 8),
              _Step(
                number: '3',
                text: 'El aprendiz debe ingresarlo durante su registro '
                    'en la aplicación para quedar asociado a ti.',
              ),
              const SizedBox(height: 8),
              _Step(
                number: '4',
                text: 'Cada código tiene un tiempo de vida limitado. '
                    'Genera uno nuevo si el anterior caduca.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Estado: sin código ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.secondary100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary200),
          ),
          child: Column(
            children: [
              const Icon(AppIcons.qrCode,
                  size: 64, color: AppColors.secondary400),
              const SizedBox(height: 16),
              Text(
                'Sin código activo',
                style:
                    text.labelLarge?.copyWith(color: AppColors.secondary500),
              ),
              const SizedBox(height: 8),
              Text(
                'No tienes un código activo. Genera uno para que tu aprendiz pueda registrarse.',
                style: text.bodyMedium?.copyWith(
                    color: AppColors.secondary400, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        AppButton(
          label:    'Generar código',
          leading:  const Icon(AppIcons.add, size: 20, color: AppColors.white),
          onPressed: _generate,
        ),
      ],
    );
  }

  Widget _buildActiveCode(RegistrationCode code, TextTheme text) {
    final remaining = code.timeRemaining;
    final hours   = remaining.inHours.toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      children: [
        // ── Tarjeta del código ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary5, AppColors.primary7],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'CÓDIGO ACTIVO',
                style: text.labelSmall?.copyWith(
                    color: AppColors.primary1, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _copyCode(code.code),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code.code,
                      style: text.titleMedium?.copyWith(
                        color: AppColors.white,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(AppIcons.copy,
                        color: AppColors.primary1, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Countdown
              _TimeChip(
                label: 'Expira en',
                value: '$hours:$minutes:$seconds',
              ),
              const SizedBox(height: 8),

              // Usos
              _TimeChip(
                label: 'Usos',
                value: '${code.uses} / ${code.maxUses}',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Acciones ──────────────────────────────────────────────────────
        AppButton(
          label:    'Copiar código',
          variant:  AppButtonVariant.secondary,
          leading:  const Icon(AppIcons.copy, size: 18),
          onPressed: () => _copyCode(code.code),
        ),
        const SizedBox(height: 12),
        AppButton(
          label:    'Revocar código',
          variant:  AppButtonVariant.danger,
          leading:  const Icon(AppIcons.block, size: 18, color: AppColors.white),
          onPressed: _revoke,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de tiempo / estadística
// ─────────────────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style:
                text.labelSmall?.copyWith(color: AppColors.primary1),
          ),
          Text(
            value,
            style: text.labelMedium?.copyWith(
                color: AppColors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paso numerado para las instrucciones
// ─────────────────────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary5,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
