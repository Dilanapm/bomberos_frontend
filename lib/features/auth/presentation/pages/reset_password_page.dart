import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scroll_body.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../providers/auth_notifier.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.token,
    required this.email,
  });

  final String token;
  final String email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _passwordError;
  String? _confirmError;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _passwordError = null;
      _confirmError = null;
      _isLoading = true;
    });

    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Ingresa la nueva contraseña.';
        _isLoading = false;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _confirmError = 'Las contraseñas no coinciden.';
        _isLoading = false;
      });
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(
            token: widget.token,
            email: widget.email,
            password: password,
            passwordConfirmation: confirm,
          );

      if (!mounted) return;
      AppToast.showSuccess(context, 'Contraseña restablecida. Inicia sesión.');
      context.go(RouteNames.login);
    } on ValidationException catch (e) {
      setState(() {
        _passwordError = e.errors['password']?.first;
        _confirmError = e.errors['password_confirmation']?.first;
      });
    } on AppException catch (e) {
      AppToast.showError(context, e.message);
    } catch (_) {
      AppToast.showError(context, 'Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Nueva contraseña'),
      body: SafeArea(
        child: AppScrollBody(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Establece tu nueva contraseña', style: text.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Ingresa y confirma tu nueva contraseña para la cuenta:\n${widget.email}',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.secondary400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Nueva contraseña',
                hintText: '••••••••',
                controller: _passwordCtrl,
                isPassword: true,
                errorText: _passwordError,
                onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirmar contraseña',
                hintText: '••••••••',
                controller: _confirmCtrl,
                isPassword: true,
                errorText: _confirmError,
                onChanged: (_) => setState(() => _confirmError = null),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Restablecer contraseña',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
