import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scroll_body.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/tap_scale.dart';
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
  bool    _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Muestra el botón de huella solo si el usuario activó la opción
  /// Y tiene un token biométrico guardado (= hay sesión previa preservada).
  Future<void> _checkBiometricAvailability() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.readBiometricEnabled();
    if (!enabled) {
      if (mounted) setState(() => _biometricAvailable = false);
      return;
    }
    final token = await storage.readBiometricToken();
    if (mounted) setState(() => _biometricAvailable = token != null);
  }

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
          // Re-verificar: si el biometric token fue borrado (sesión expirada)
          // el botón de huella debe desaparecer automáticamente.
          _checkBiometricAvailability();
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
            child: AppScrollBody(
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

                    // ── Botón de huella (visible solo si está habilitado) ───
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.secondary700
                                  : AppColors.secondary200,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.secondary700
                                  : AppColors.secondary200,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _BiometricButton(
                        isLoading: isLoading,
                        onTap: () => ref
                            .read(authNotifierProvider.notifier)
                            .loginWithBiometric(),
                      ),
                    ],

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

// ─────────────────────────────────────────────────────────────────────────────

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TapScale(
      enabled: !isLoading,
      child: GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isLoading ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary5, width: 1.5),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary5,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.primary5,
                      size: 34,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresar con huella',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.primary5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
