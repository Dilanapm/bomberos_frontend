import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_settings_tile.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/biometric_notifier.dart';
import '../providers/profile_notifier.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _currentPwCtrl  = TextEditingController();
  final _newPwCtrl      = TextEditingController();
  final _confirmPwCtrl  = TextEditingController();

  bool _changingPw              = false;
  Map<String, String?> _pwErrors = {};

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    setState(() { _pwErrors = {}; _changingPw = true; });
    try {
      await ref.read(profileNotifierProvider.notifier).changePassword(
            currentPassword:      _currentPwCtrl.text,
            password:             _newPwCtrl.text,
            passwordConfirmation: _confirmPwCtrl.text,
          );
      if (!mounted) return;
      AppToast.showSuccess(context, 'Contraseña actualizada.');
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
    } on ValidationException catch (e) {
      setState(() =>
          _pwErrors = e.errors.map((k, v) => MapEntry(k, v.first)));
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  void _showPasswordSheet() {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.dark4 : AppColors.secondary200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Cambiar contraseña', style: textTheme.titleSmall),
              const SizedBox(height: 20),
              AppTextField(
                label:      'Contraseña actual',
                hintText:   '••••••••',
                controller: _currentPwCtrl,
                isPassword: true,
                errorText:  _pwErrors['current_password'],
                onChanged:  (_) => setState(
                    () => _pwErrors.remove('current_password')),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label:      'Nueva contraseña',
                hintText:   '••••••••',
                controller: _newPwCtrl,
                isPassword: true,
                errorText:  _pwErrors['password'],
                onChanged:  (_) =>
                    setState(() => _pwErrors.remove('password')),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label:      'Confirmar nueva contraseña',
                hintText:   '••••••••',
                controller: _confirmPwCtrl,
                isPassword: true,
                errorText:  _pwErrors['password_confirmation'],
                onChanged:  (_) => setState(
                    () => _pwErrors.remove('password_confirmation')),
              ),
              const SizedBox(height: 20),
              AppButton(
                label:     'Actualizar contraseña',
                isLoading: _changingPw,
                onPressed: _changingPw ? null : () async {
                  final nav = Navigator.of(context);
                  await _savePassword();
                  if (mounted && _pwErrors.isEmpty) nav.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final divColor  = isDark ? AppColors.dark3 : AppColors.secondary100;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Seguridad',
        backgroundColor: isDark ? AppColors.dark1 : AppColors.primary5,
        foregroundColor: AppColors.white,
        showDivider: false,
      ),
      body: AppScrollBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  // ── Cambiar contraseña ──────────────────────────────────
                  AppChevronTile(
                    icon:      Icons.lock_outline_rounded,
                    iconColor: AppColors.info500,
                    label:     'Cambiar contraseña',
                    subtitle:  'Actualiza tu contraseña de acceso',
                    onTap:     _showPasswordSheet,
                  ),
                  Divider(height: 1, color: divColor),
                  // ── Huella dactilar ─────────────────────────────────────
                  _BiometricTile(isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de biométrico (widget separado para aislar rebuilds) ─────────────────

class _BiometricTile extends ConsumerWidget {
  const _BiometricTile({required this.isDark});
  final bool isDark;

  String _unavailableSubtitle(BiometricAvailability av) {
    switch (av) {
      case BiometricAvailability.noHardware:
        return 'Tu dispositivo no tiene sensor biométrico';
      case BiometricAvailability.notEnrolled:
        return 'Registra una huella en los ajustes del sistema';
      default:
        return 'No disponible en este dispositivo';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioAsync = ref.watch(biometricNotifierProvider);

    return bioAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (bio) {
        if (!bio.isAvailable) {
          // Mostrar tile deshabilitado con explicación
          return AppChevronTile(
            icon:      Icons.fingerprint_rounded,
            iconColor: isDark ? AppColors.secondary600 : AppColors.secondary300,
            label:     'Acceso por huella dactilar',
            subtitle:  _unavailableSubtitle(bio.availability),
            onTap:     () {},
          );
        }

        return AppToggleTile(
          icon:      Icons.fingerprint_rounded,
          iconColor: bio.isEnabled
              ? AppColors.success600
              : (isDark ? AppColors.secondary400 : AppColors.secondary500),
          label:     'Acceso por huella dactilar',
          value:     bio.isEnabled,
          onChanged: bio.isLoading
              ? (_) {}
              : (enable) => ref
                  .read(biometricNotifierProvider.notifier)
                  .toggle(enable: enable),
        );
      },
    );
  }
}
