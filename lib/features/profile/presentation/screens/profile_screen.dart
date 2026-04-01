import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_settings_tile.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../app/theme/theme_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/profile_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── Edit controllers ──────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _currentPwCtrl   = TextEditingController();
  final _newPwCtrl       = TextEditingController();
  final _confirmPwCtrl   = TextEditingController();

  bool _editingName    = false;
  bool _changingPw     = false;
  bool _notificationsOn = true; // TODO: conectar a preferences provider

  Map<String, String?> _profileErrors  = {};
  Map<String, String?> _passwordErrors = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  void _startEdit(String name, String? username) {
    _nameCtrl.text     = name;
    _usernameCtrl.text = username ?? '';
    setState(() => _editingName = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _profileErrors = {});
    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            name:     _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
          );
      if (!mounted) return;
      AppToast.showSuccess(context, 'Perfil actualizado.');
      setState(() => _editingName = false);
    } on ValidationException catch (e) {
      setState(() =>
          _profileErrors = e.errors.map((k, v) => MapEntry(k, v.first)));
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _passwordErrors = {};
      _changingPw     = true;
    });
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
          _passwordErrors = e.errors.map((k, v) => MapEntry(k, v.first)));
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  Future<void> _logout() async {
    final ok = await AppConfirmDialog.show(
      context,
      title:       'Cerrar sesión',
      message:     '¿Deseas cerrar tu sesión?',
      confirmText: 'Salir',
      isDanger:    true,
    );
    if (!ok || !mounted) return;
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final textTheme   = Theme.of(context).textTheme;
    final profileState = ref.watch(profileNotifierProvider);
    final user        = profileState.user;
    final isSaving    = profileState.isLoading;

    final bgColor  = isDark ? AppColors.dark0  : AppColors.secondary50;
    final divColor = isDark ? AppColors.dark3  : AppColors.secondary100;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppAppBar(
        title: isDark ? 'Configuraciones' : 'Mi Perfil',
        backgroundColor: isDark ? AppColors.dark0 : AppColors.white,
        foregroundColor: isDark ? AppColors.secondary50 : AppColors.secondary700,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Card: Avatar + nombre + rol ─────────────────────────────────
            AppCard(
              child: _editingName
                  ? _EditProfileForm(
                      nameCtrl:      _nameCtrl,
                      usernameCtrl:  _usernameCtrl,
                      errors:        _profileErrors,
                      isSaving:      isSaving,
                      onSave:        _saveProfile,
                      onCancel:      () => setState(() => _editingName = false),
                      onChanged:     (k) => setState(() => _profileErrors.remove(k)),
                    )
                  : _ProfileHeader(
                      user:    user,
                      isDark:  isDark,
                      onEdit:  () => _startEdit(user.name, user.username),
                    ),
            ),

            const SizedBox(height: 16),

            // ── Card: Configuración ─────────────────────────────────────────
            AppCard(
              child: Column(
                children: [
                  AppToggleTile(
                    icon:     AppIcons.darkMode,
                    iconColor: isDark ? AppColors.info400 : AppColors.secondary400,
                    label:    'Modo Oscuro',
                    value:    isDark,
                    onChanged: (_) => ref
                        .read(themeModeProvider.notifier)
                        .toggle(Theme.of(context).brightness),
                  ),
                  Divider(height: 1, color: divColor),
                  AppToggleTile(
                    icon:      AppIcons.notifications,
                    iconColor: AppColors.primary5,
                    label:     'Notificaciones',
                    value:     _notificationsOn,
                    onChanged: (v) => setState(() => _notificationsOn = v),
                  ),
                  Divider(height: 1, color: divColor),
                  AppChevronTile(
                    icon:      AppIcons.security,
                    iconColor: AppColors.success600,
                    label:     'Seguridad',
                    onTap:     () => _showPasswordSheet(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Card: Ayuda ─────────────────────────────────────────────────
            AppCard(
              child: AppChevronTile(
                icon:      AppIcons.help,
                iconColor: isDark ? AppColors.secondary300 : AppColors.secondary400,
                label:     'Ayuda y Soporte',
                onTap:     () {}, // TODO: navegar a pantalla de ayuda
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón cerrar sesión ─────────────────────────────────────────
            _LogoutButton(isDark: isDark, onTap: _logout),

            const SizedBox(height: 16),

            // ── Footer versión ──────────────────────────────────────────────
            Text(
              'Bomberos TG App - Versión 1.0.0',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.secondary500 : AppColors.secondary400,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet para cambiar contraseña ──────────────────────────────────
  void _showPasswordSheet(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
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
              errorText:  _passwordErrors['current_password'],
              onChanged:  (_) => setState(
                  () => _passwordErrors.remove('current_password')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label:      'Nueva contraseña',
              hintText:   '••••••••',
              controller: _newPwCtrl,
              isPassword: true,
              errorText:  _passwordErrors['password'],
              onChanged:  (_) =>
                  setState(() => _passwordErrors.remove('password')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label:      'Confirmar nueva contraseña',
              hintText:   '••••••••',
              controller: _confirmPwCtrl,
              isPassword: true,
              errorText:  _passwordErrors['password_confirmation'],
              onChanged:  (_) => setState(
                  () => _passwordErrors.remove('password_confirmation')),
            ),
            const SizedBox(height: 20),
            AppButton(
              label:     'Actualizar contraseña',
              isLoading: _changingPw,
              onPressed: _changingPw ? null : () async {
                final nav = Navigator.of(context);
                await _savePassword();
                if (mounted) nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cabecera de perfil (avatar + nombre + rol)
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.onEdit,
  });

  final dynamic user;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme   = Theme.of(context).textTheme;
    final textPrimary = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final roleBg      = isDark ? AppColors.dark3        : AppColors.secondary100;
    final roleText    = isDark ? AppColors.secondary300 : AppColors.secondary500;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar con botón de edición
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.dark3 : AppColors.secondary200,
                  border: Border.all(
                    color: isDark ? AppColors.dark4 : AppColors.secondary100,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: user.avatarUrl != null
                    ? Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) =>
                            _AvatarFallback(name: user.name, isDark: isDark),
                      )
                    : _AvatarFallback(name: user.name, isDark: isDark),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary5,
                    ),
                    child: const Icon(
                      AppIcons.edit,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nombre con lápiz de edición
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: textTheme.titleSmall?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary5,
                  ),
                  child: const Icon(
                    AppIcons.edit,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: roleBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.dark4 : AppColors.secondary200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.aprendiz, size: 12, color: roleText),
                const SizedBox(width: 5),
                Text(
                  'ROL ${user.role.toUpperCase()}',
                  style: textTheme.labelSmall?.copyWith(
                    color: roleText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.isDark});
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDark ? AppColors.secondary300 : AppColors.secondary600,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Formulario de edición de nombre
// ═══════════════════════════════════════════════════════════════════════════

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.errors,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    required this.onChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final Map<String, String?> errors;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AppTextField(
            label:      'Nombre',
            controller: nameCtrl,
            errorText:  errors['name'],
            onChanged:  (_) => onChanged('name'),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label:      'Usuario',
            controller: usernameCtrl,
            errorText:  errors['username'],
            onChanged:  (_) => onChanged('username'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label:     'Guardar',
                  isLoading: isSaving,
                  onPressed: isSaving ? null : onSave,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label:    'Cancelar',
                  variant:  AppButtonVariant.secondary,
                  onPressed: onCancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Botón de cerrar sesión
// ═══════════════════════════════════════════════════════════════════════════

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isDark, required this.onTap});
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary5, width: 1.5),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.logout, color: AppColors.primary5, size: 20),
            const SizedBox(width: 10),
            Text(
              'Cerrar Sesión',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primary5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
