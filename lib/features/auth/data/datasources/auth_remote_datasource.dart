import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fuente de datos remota: habla con el backend Laravel.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  // ── Login ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(RegisterParams params) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name':                  params.name,
          'username':              params.username,
          'email':                 params.email,
          'password':              params.password,
          'password_confirmation': params.passwordConfirmation,
          'registration_code':     params.registrationCode,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Email Verify ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> emailVerify({
    required int userId,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.emailVerify,
        data: {'user_id': userId, 'code': code},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Email Resend ──────────────────────────────────────────────────────────

  Future<void> emailResend({required int userId}) async {
    try {
      await _dio.post(
        ApiEndpoints.emailResend,
        data: {'user_id': userId},
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Reset Password ────────────────────────────────────────────────────────

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token':                 token,
          'email':                 email,
          'password':              password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Me ────────────────────────────────────────────────────────────────────

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? res.data as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// El interceptor ya convirtió el error en [AppException] y lo puso en
  /// [DioException.error]. Lo extraemos para lanzarlo directamente.
  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

/// Provider de la fuente de datos.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.read(dioClientProvider);
  return AuthRemoteDataSource(client.dio);
});
