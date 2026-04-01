import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError    = null;
      _passwordError = null;
    });

    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Ingresa tu correo electrónico.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Ingresa tu contraseña.');
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .login(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final size      = MediaQuery.sizeOf(context);

    // ── Colores adaptativos al tema ──────────────────────────────────────────
    final bgColor        = isDark ? AppColors.dark0    : AppColors.secondary50;
    final titleColor     = isDark ? AppColors.white    : AppColors.secondary900;
    final subtitleColor  = isDark ? AppColors.secondary300 : AppColors.secondary500;
    final versionColor   = isDark ? AppColors.secondary500 : AppColors.secondary400;

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          if (e is EmailNotVerifiedException) {
            context.push(
              RouteNames.otp,
              extra: {'userId': e.userId, 'email': e.email},
            );
          } else if (e is ValidationException) {
            setState(() {
              _emailError    = e.errors['email']?.first;
              _passwordError = e.errors['password']?.first;
            });
          } else if (e is AppException) {
            AppToast.showError(context, e.message);
          } else {
            AppToast.showError(context, 'Error inesperado. Intenta de nuevo.');
          }
        },
      );
    });

    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Gradiente rojo en la parte superior (igual que WelcomeScreen) ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.35,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido principal ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.06),

                    // ── Logo ───────────────────────────────────────────────
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.logoOverlay,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Título ─────────────────────────────────────────────
                    Text(
                      'Bomberos I',
                      style: textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Subtítulo ──────────────────────────────────────────
                    Text(
                      'Sistema de apoyo al entrenamiento y\nevaluación de EPP',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // ── Campo correo ───────────────────────────────────────
                    AppTextField(
                      label: 'Usuario o Correo',
                      hintText: 'ej. bombero@tg.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      prefixIcon: AppIcons.profile,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),

                    const SizedBox(height: 16),

                    // ── Campo contraseña ───────────────────────────────────
                    AppTextField(
                      label: 'Contraseña',
                      hintText: '••••••••',
                      controller: _passwordCtrl,
                      isPassword: true,
                      errorText: _passwordError,
                      prefixIcon: AppIcons.security,
                      onChanged: (_) => setState(() => _passwordError = null),
                    ),

                    // ── ¿Olvidaste? ────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(RouteNames.forgotPassword),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Botón Ingresar ─────────────────────────────────────
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.buttonShadow,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AppButton(
                        label: 'Ingresar',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Botón Crear Cuenta ─────────────────────────────────
                    AppButton(
                      label: 'Crear Cuenta',
                      variant: AppButtonVariant.secondary,
                      onPressed: isLoading
                          ? null
                          : () => context.push(RouteNames.register),
                    ),

                    const SizedBox(height: 32),

                    // ── Footer versión ─────────────────────────────────────
                    Text(
                      'Versión 1.0.0 © Bomberos TG',
                      style: textTheme.labelSmall?.copyWith(
                        color: versionColor,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

