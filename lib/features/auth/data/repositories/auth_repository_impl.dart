import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementación concreta de [AuthRepository] usando [AuthRemoteDataSource].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AuthResult> login(LoginParams params) async {
    final body = await _remote.login(
      email: params.email,
      password: params.password,
    );
    // Respuesta 200: { status, data: { token, token_type, expires_at, user{...} } }
    final inner = body['data'] as Map<String, dynamic>;
    final token = inner['token'] as String;
    final userJson = inner['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    return AuthResult(token: token, user: user);
  }

  @override
  Future<RegisterResult> register(RegisterParams params) async {
    final data = await _remote.register(params);
    // Respuesta 201: { data: { user_id, email } }
    final inner = data['data'] as Map<String, dynamic>;
    return RegisterResult(
      userId: (inner['user_id'] as num).toInt(),
      email:  inner['email'] as String,
    );
  }

  @override
  Future<AuthResult> verifyOtp({
    required int userId,
    required String code,
  }) async {
    final body = await _remote.emailVerify(userId: userId, code: code);
    // Respuesta 200: { status, data: { token, token_type, expires_at, user{...} } }
    final inner = body['data'] as Map<String, dynamic>;
    final token = inner['token'] as String;
    final userJson = inner['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    return AuthResult(token: token, user: user);
  }

  @override
  Future<void> resendOtp({required int userId}) async {
    await _remote.emailResend(userId: userId);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remote.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _remote.resetPassword(
      token:                token,
      email:                email,
      password:             password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
  }

  @override
  Future<User> getMe() async {
    return _remote.getMe();
  }
}

/// Provider del repositorio (apunta a la implementación concreta).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.read(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remote);
});
