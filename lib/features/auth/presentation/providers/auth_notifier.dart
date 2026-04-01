import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
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

      state = AsyncData(AuthAuthenticated(result.user));
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
    try {
      await ref.read(logoutUseCaseProvider).call();
    } catch (_) {
      // Aunque falle el request, limpiamos localmente
    } finally {
      await ref.read(secureStorageProvider).deleteAll();
      state = const AsyncData(AuthUnauthenticated());
    }
  }
}

/// Provider global del estado de autenticación.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
