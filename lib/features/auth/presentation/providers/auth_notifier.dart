import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Inyectar callbacks globales en el cliente Dio para manejar
    // errores de sesión sin que el repositorio sepa del router.
    final dioClient = ref.read(dioClientProvider);
    dioClient.setGlobalCallbacks(
      onUnauthenticated: () async {
        state = const AsyncData(AuthUnauthenticated());
      },
      onAccountDisabled: (_) async {
        state = const AsyncData(AuthUnauthenticated());
      },
      onRoleForbidden: () async {
        state = const AsyncData(AuthUnauthenticated());
      },
    );

    // Verificar sesión guardada
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readToken();

    if (token == null) return const AuthUnauthenticated();

    try {
      final user = await ref.read(getMeUseCaseProvider).call();
      return AuthAuthenticated(user);
    } catch (_) {
      await storage.deleteAll();
      return const AuthUnauthenticated();
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(loginUseCaseProvider)
          .call(LoginParams(email: email, password: password));

      final storage = ref.read(secureStorageProvider);
      await storage.writeToken(result.token);
      await storage.writeUserRole(result.user.role);
      await storage.writeUserId(result.user.id);

      // Si el biométrico está habilitado, actualizar el token guardado
      // para que el re-login con huella use credenciales frescas.
      final biometricEnabled = await storage.readBiometricEnabled();
      if (biometricEnabled) {
        await storage.writeBiometricToken(result.token);
      }

      state = AsyncData(AuthAuthenticated(result.user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Biometric Login ───────────────────────────────────────────────────────

  /// Autentica con huella dactilar y restablece la sesión con el token guardado.
  ///
  /// Flujo:
  /// 1. Lanza el prompt de huella.
  /// 2. Si pasa: usa [biometricToken] para llamar a `/auth/me`.
  /// 3. Si el token expiró: lo limpia y emite un error claro para que el
  ///    usuario inicie sesión con contraseña.
  Future<void> loginWithBiometric() async {
    state = const AsyncLoading();
    try {
      final authenticated = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: 'Ingresa a tu cuenta con huella dactilar');

      if (!authenticated) {
        // Usuario canceló el diálogo — volver al estado sin sesión sin error.
        state = const AsyncData(AuthUnauthenticated());
        return;
      }

      final storage    = ref.read(secureStorageProvider);
      final savedToken = await storage.readBiometricToken();

      if (savedToken == null) {
        state = AsyncError(
          UnauthenticatedException(
            'Sesión expirada. Inicia sesión con tu contraseña.',
          ),
          StackTrace.current,
        );
        return;
      }

      // Restaurar el token para que el interceptor Dio lo incluya en /auth/me.
      await storage.writeToken(savedToken);

      try {
        final user = await ref.read(getMeUseCaseProvider).call();
        await storage.writeUserRole(user.role);
        await storage.writeUserId(user.id);
        state = AsyncData(AuthAuthenticated(user));
      } catch (_) {
        // Token expirado en el servidor — limpiar todo para forzar re-login.
        await storage.deleteBiometricToken();
        await storage.deleteAll();
        state = AsyncError(
          UnauthenticatedException(
            'La sesión expiró. Inicia sesión con tu contraseña.',
          ),
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<RegisterResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String registrationCode,
  }) async {
    // No cambiamos el auth state (aún sin token), solo lanzamos si hay error.
    final result = await ref.read(registerUseCaseProvider).call(
          RegisterParams(
            name:                  name,
            username:              username,
            email:                 email,
            password:              password,
            passwordConfirmation:  passwordConfirmation,
            registrationCode:      registrationCode,
          ),
        );
    return result;
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> verifyOtp({required int userId, required String code}) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(verifyOtpUseCaseProvider)
          .call(userId: userId, code: code);

      final storage = ref.read(secureStorageProvider);
      await storage.writeToken(result.token);
      await storage.writeUserRole(result.user.role);
      await storage.writeUserId(result.user.id);

      state = AsyncData(AuthAuthenticated(result.user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────

  Future<void> resendOtp({required int userId}) async {
    await ref.read(resendOtpUseCaseProvider).call(userId: userId);
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  Future<void> forgotPassword({required String email}) async {
    await ref.read(forgotPasswordUseCaseProvider).call(email: email);
  }

  // ── Reset Password ────────────────────────────────────────────────────────

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await ref.read(resetPasswordUseCaseProvider).call(
          token:                token,
          email:                email,
          password:             password,
          passwordConfirmation: passwordConfirmation,
        );
  }

  // ── Update user (called by other features) ────────────────────────────────

  void updateUser(User user) {
    state = AsyncData(AuthAuthenticated(user));
  }

  // ── Refresh Me (silencioso, no cambia a loading) ──────────────────────────
  /// Llama a /auth/me y actualiza los datos del usuario (incluyendo permisos)
  /// sin interrumpir la UI. Se usa al reanudar la app y antes de entrar a
  /// módulos protegidos.
  Future<void> refreshMe() async {
    // Solo refrescamos si ya hay una sesión autenticada
    final isAuthenticated = state.when(
      data:    (s) => s is AuthAuthenticated,
      loading: () => false,
      error:   (e, st) => false,
    );
    if (!isAuthenticated) return;
    try {
      final user = await ref.read(getMeUseCaseProvider).call();
      state = AsyncData(AuthAuthenticated(user));
    } catch (_) {
      // Fallo silencioso: si hay error de red, mantenemos los permisos actuales
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final storage          = ref.read(secureStorageProvider);
    final biometricEnabled = await storage.readBiometricEnabled();

    if (biometricEnabled) {
      // Con huella habilitada NO revocamos el token en el servidor.
      // Si lo revocáramos, el token guardado en biometricToken quedaría
      // inválido y el re-login biométrico fallaría con 401.
      // El token expirará solo según la política del backend.
      await storage.deleteAuthData();
    } else {
      // Sin huella: revocar el token en el servidor y limpiar todo.
      try {
        await ref.read(logoutUseCaseProvider).call();
      } catch (_) {
        // Si falla la llamada, limpiamos localmente de todas formas.
      }
      await storage.deleteAll();
    }

    state = const AsyncData(AuthUnauthenticated());
  }
}

/// Provider global del estado de autenticación.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
