import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../providers/auth_notifier.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _isLoading  = false;
  bool _sent       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = null;
      _isLoading  = true;
    });

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Ingresa tu correo electrónico.';
        _isLoading  = false;
      });
      return;
    }

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _sent = true);
    } on ValidationException catch (e) {
      setState(() => _emailError = e.errors['email']?.first);
    } on AppException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, 'Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Recuperar contraseña'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _buildSuccess(text) : _buildForm(text),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Olvidaste tu contraseña?', style: text.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo y te enviaremos un enlace para restablecerla.',
          style: text.bodyMedium?.copyWith(
              color: AppColors.secondary400, height: 1.5),
        ),
        const SizedBox(height: 40),
        AppTextField(
          label: 'Correo electrónico',
          hintText: 'ejemplo@correo.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Enviar enlace',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSuccess(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(AppIcons.email,
            size: 72, color: AppColors.success500),
        const SizedBox(height: 24),
        Text('¡Revisa tu correo!',
            style: text.titleSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Si el correo existe en nuestro sistema, recibirás un enlace para restablecer tu contraseña.',
          style: text.bodyMedium?.copyWith(
              color: AppColors.secondary400, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
