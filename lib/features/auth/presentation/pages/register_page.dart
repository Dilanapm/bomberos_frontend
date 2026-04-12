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

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  Map<String, String?> _errors = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errors = {};
      _isLoading = true;
    });

    try {
      final result = await ref.read(authNotifierProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            passwordConfirmation: _confirmCtrl.text,
            registrationCode: _codeCtrl.text.trim(),
          );

      if (!mounted) return;
      context.pushReplacement(
        RouteNames.otp,
        extra: {'userId': result.userId, 'email': result.email},
      );
    } on ValidationException catch (e) {
      final mapped = e.errors.map((key, value) => MapEntry(key, value.first));
      setState(() => _errors = mapped);
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
      appBar: AppAppBar(title: 'Crear cuenta'),
      body: SafeArea(
        child: AppScrollBody(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completa tus datos', style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Necesitas un código de registro de tu instructor.',
                style: text.bodyMedium?.copyWith(color: AppColors.secondary400),
              ),
              const SizedBox(height: 28),
              AppTextField(
                label: 'Nombre completo',
                hintText: 'Juan Pérez',
                controller: _nameCtrl,
                errorText: _errors['name'],
                onChanged: (_) => setState(() => _errors.remove('name')),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Usuario',
                hintText: 'juan_perez',
                controller: _usernameCtrl,
                errorText: _errors['username'],
                onChanged: (_) => setState(() => _errors.remove('username')),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                errorText: _errors['email'],
                onChanged: (_) => setState(() => _errors.remove('email')),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Contraseña',
                hintText: '••••••••',
                controller: _passwordCtrl,
                isPassword: true,
                errorText: _errors['password'],
                onChanged: (_) => setState(() => _errors.remove('password')),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirmar contraseña',
                controller: _confirmCtrl,
                isPassword: true,
                errorText: _errors['password_confirmation'],
                onChanged: (_) =>
                    setState(() => _errors.remove('password_confirmation')),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Código de registro',
                hintText: 'Ingresa el código de tu instructor',
                controller: _codeCtrl,
                errorText: _errors['registration_code'],
                onChanged: (_) =>
                    setState(() => _errors.remove('registration_code')),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Crear cuenta',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta?', style: text.bodyMedium),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Inicia sesión',
                      style: text.labelMedium?.copyWith(
                        color: AppColors.primary5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
