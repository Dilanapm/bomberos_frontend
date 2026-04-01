import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/profile_notifier.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // ── Edit Profile ──────────────────────────────────────────────────────────
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _editMode = false;

  // ── Change Password ───────────────────────────────────────────────────────
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _changingPw     = false;

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
    setState(() => _editMode = true);
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
      setState(() => _editMode = false);
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

  Future<void> _deleteAvatar() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title:       'Eliminar foto',
      message:     '¿Deseas eliminar tu foto de perfil?',
      confirmText: 'Eliminar',
      isDanger:    true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(profileNotifierProvider.notifier).deleteAvatar();
      if (!mounted) return;
      AppToast.showSuccess(context, 'Foto eliminada.');
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title:       'Cerrar sesión',
      message:     '¿Deseas cerrar tu sesión?',
      confirmText: 'Salir',
      isDanger:    true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profileAsync = ref.watch(profileNotifierProvider);
    final user = profileAsync.user;
    final isSaving = profileAsync.isLoading;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Mi perfil',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ─────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.secondary200,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: text.titleMedium
                                ?.copyWith(color: AppColors.secondary700),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (user.avatarUrl != null)
                    TextButton.icon(
                      onPressed: isSaving ? null : _deleteAvatar,
                      icon: const Icon(AppIcons.delete, size: 18),
                      label: const Text('Eliminar foto'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary6),
                    ),
                  // TODO Phase 4: agregar subida de avatar con image_picker
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ── Datos del perfil ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Datos del perfil', style: text.labelLarge),
                if (!_editMode)
                  TextButton(
                    onPressed: () => _startEdit(user.name, user.username),
                    child: const Text('Editar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_editMode) ...[
              AppTextField(
                label:     'Nombre',
                controller: _nameCtrl,
                errorText:  _profileErrors['name'],
                onChanged: (_) =>
                    setState(() => _profileErrors.remove('name')),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label:     'Usuario',
                controller: _usernameCtrl,
                errorText:  _profileErrors['username'],
                onChanged: (_) =>
                    setState(() => _profileErrors.remove('username')),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label:     'Guardar',
                      isLoading: isSaving,
                      onPressed: isSaving ? null : _saveProfile,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label:   'Cancelar',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => setState(() => _editMode = false),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _infoRow('Nombre',   user.name,     text),
              _infoRow('Usuario',  user.username != null ? '@${user.username}' : '—', text),
              _infoRow('Correo',   user.email,    text),
              _infoRow('Rol',      user.role,     text),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ── Cambiar contraseña ─────────────────────────────────────────
            Text('Cambiar contraseña', style: text.labelLarge),
            const SizedBox(height: 16),
            AppTextField(
              label:     'Contraseña actual',
              hintText:  '••••••••',
              controller: _currentPwCtrl,
              isPassword: true,
              errorText:  _passwordErrors['current_password'],
              onChanged: (_) =>
                  setState(() => _passwordErrors.remove('current_password')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label:     'Nueva contraseña',
              hintText:  '••••••••',
              controller: _newPwCtrl,
              isPassword: true,
              errorText:  _passwordErrors['password'],
              onChanged: (_) =>
                  setState(() => _passwordErrors.remove('password')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label:     'Confirmar nueva contraseña',
              hintText:  '••••••••',
              controller: _confirmPwCtrl,
              isPassword: true,
              errorText:  _passwordErrors['password_confirmation'],
              onChanged: (_) => setState(
                  () => _passwordErrors.remove('password_confirmation')),
            ),
            const SizedBox(height: 20),
            AppButton(
              label:     'Actualizar contraseña',
              isLoading: _changingPw,
              onPressed: _changingPw ? null : _savePassword,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: text.labelMedium
                    ?.copyWith(color: AppColors.secondary400)),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
