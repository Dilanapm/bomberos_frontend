import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/tap_scale.dart';
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
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _editingName     = false;
  bool _notificationsOn = true; // TODO: conectar a preferences provider

  Map<String, String?> _profileErrors = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
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

      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final compact = constraints.maxHeight <= 620;
          final ultraCompact = constraints.maxHeight <= 600;
          final vPad = ultraCompact ? 12.0 : (compact ? 16.0 : 20.0);
          final gapS = ultraCompact ? 8.0 : (compact ? 12.0 : 16.0);
          final gapM = ultraCompact ? 12.0 : (compact ? 20.0 : 28.0);
          final gapFooter = ultraCompact ? 8.0 : (compact ? 16.0 : 24.0);

          final content = Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Card: Avatar + nombre + rol ─────────────────────────────
                AppCard(
                  child: _editingName
                      ? _EditProfileForm(
                          nameCtrl: _nameCtrl,
                          usernameCtrl: _usernameCtrl,
                          errors: _profileErrors,
                          isSaving: isSaving,
                          onSave: _saveProfile,
                          onCancel: () =>
                              setState(() => _editingName = false),
                          onChanged: (k) =>
                              setState(() => _profileErrors.remove(k)),
                          compact: compact,
                          ultraCompact: ultraCompact,
                        )
                      : _ProfileHeader(
                          user: user,
                          isDark: isDark,
                          onEdit: () =>
                              _startEdit(user.name, user.username),
                          compact: compact,
                          ultraCompact: ultraCompact,
                        ),
                ),

                SizedBox(height: gapS),

                // ── Card: Configuración ─────────────────────────────────────
                AppCard(
                  child: Column(
                    children: [
                      AppToggleTile(
                        icon: AppIcons.darkMode,
                        iconColor:
                            isDark ? AppColors.info400 : AppColors.secondary400,
                        label: 'Modo Oscuro',
                        value: isDark,
                        onChanged: (_) => ref
                            .read(themeModeProvider.notifier)
                            .toggle(Theme.of(context).brightness),
                        dense: compact,
                      ),
                      Divider(height: 1, color: divColor),
                      AppToggleTile(
                        icon: AppIcons.notifications,
                        iconColor: AppColors.primary5,
                        label: 'Notificaciones',
                        value: _notificationsOn,
                        onChanged: (v) =>
                            setState(() => _notificationsOn = v),
                        dense: compact,
                      ),
                      Divider(height: 1, color: divColor),
                      AppChevronTile(
                        icon: AppIcons.security,
                        iconColor: AppColors.success600,
                        label: 'Seguridad',
                        subtitle: 'Contraseña y acceso biométrico',
                        onTap: () => context.push(RouteNames.security),
                        dense: compact,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: gapS),

                // ── Card: Ayuda ─────────────────────────────────────────────
                // AppCard(
                //   child: AppChevronTile(
                //     icon: AppIcons.help,
                //     iconColor:
                //         isDark ? AppColors.secondary300 : AppColors.secondary400,
                //     label: 'Ayuda y Soporte',
                //     onTap: () {}, // TODO: navegar a pantalla de ayuda
                //     dense: compact,
                //   ),
                // ),

                // SizedBox(height: compact ? gapS : gapM),

                // ── Botón cerrar sesión ─────────────────────────────────────
                _LogoutButton(
                  isDark: isDark,
                  onTap: _logout,
                  dense: ultraCompact,
                ),

                SizedBox(height: gapS),

                // ── Footer versión ──────────────────────────────────────────
                Text(
                  'Bomberos TG App - Versión 1.0.0',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color:
                        isDark ? AppColors.secondary500 : AppColors.secondary400,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: gapFooter),
              ],
            ),
          );

          return content;
        },
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
    required this.compact,
    required this.ultraCompact,
  });

  final dynamic user;
  final bool isDark;
  final VoidCallback onEdit;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme   = Theme.of(context).textTheme;
    final textPrimary = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final roleBg      = isDark ? AppColors.dark3        : AppColors.secondary100;
    final roleText    = isDark ? AppColors.secondary300 : AppColors.secondary500;

    final cardPad = ultraCompact ? 12.0 : (compact ? 16.0 : 20.0);
    final avatarSize = ultraCompact ? 72.0 : (compact ? 88.0 : 96.0);
    final gapS = ultraCompact ? 8.0 : (compact ? 12.0 : 16.0);
    final gapXS = ultraCompact ? 6.0 : (compact ? 8.0 : 10.0);
    final editBtnSize = ultraCompact ? 26.0 : 30.0;
    final editIconSize = ultraCompact ? 14.0 : 16.0;
    final miniEditIconSize = ultraCompact ? 11.0 : 12.0;

    return Padding(
      padding: EdgeInsets.all(cardPad),
      child: Column(
        children: [
          // Avatar con botón de edición
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
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
                    width: editBtnSize,
                    height: editBtnSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary5,
                    ),
                    child: Icon(
                      AppIcons.edit,
                      size: editIconSize,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: gapS),

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
                  child: Icon(
                    AppIcons.edit,
                    size: miniEditIconSize,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: gapXS),

          // Badge de rol
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ultraCompact ? 10 : 12,
              vertical: ultraCompact ? 4 : 5,
            ),
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
                Icon(
                  AppIcons.aprendiz,
                  size: ultraCompact ? 11 : 12,
                  color: roleText,
                ),
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
    required this.compact,
    required this.ultraCompact,
  });

  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final Map<String, String?> errors;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<String> onChanged;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final pad = ultraCompact ? 12.0 : (compact ? 16.0 : 20.0);
    final gapS = ultraCompact ? 8.0 : (compact ? 10.0 : 12.0);

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        children: [
          AppTextField(
            label:      'Nombre',
            controller: nameCtrl,
            errorText:  errors['name'],
            onChanged:  (_) => onChanged('name'),
          ),
          SizedBox(height: gapS),
          AppTextField(
            label:      'Usuario',
            controller: usernameCtrl,
            errorText:  errors['username'],
            onChanged:  (_) => onChanged('username'),
          ),
          SizedBox(height: ultraCompact ? 12 : (compact ? 16 : 20)),
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
  const _LogoutButton({required this.isDark, required this.onTap, this.dense = false});
  final bool isDark;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TapScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: dense ? 44 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary5, width: 1.5),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.logout,
                color: AppColors.primary5,
                size: dense ? 18 : 20,
              ),
              SizedBox(width: dense ? 8 : 10),
              Text(
                'Cerrar Sesión',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary5,
                  fontWeight: FontWeight.w600,
                  fontSize: dense ? 13 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
