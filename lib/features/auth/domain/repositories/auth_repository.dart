import '../entities/user.dart';

/// Parámetros para el inicio de sesión.
class LoginParams {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}

/// Parámetros para el registro de un aprendiz.
class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.registrationCode,
  });

  final String name;
  final String username;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String registrationCode;
}

/// Resultado del login / verify-OTP que contiene el token y el usuario.
class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final User user;
}

/// Resultado del registro (aún sin token, esperando OTP).
class RegisterResult {
  const RegisterResult({required this.userId, required this.email});
  final int userId;
  final String email;
}

/// Interfaz abstracta del repositorio de autenticación.
/// La capa de dominio sólo conoce esta abstracción.
abstract class AuthRepository {
  /// Inicia sesión → [AuthResult] con token y usuario.
  Future<AuthResult> login(LoginParams params);

  /// Registra un aprendiz → [RegisterResult] sin token.
  Future<RegisterResult> register(RegisterParams params);

  /// Verifica el código OTP del correo → [AuthResult].
  Future<AuthResult> verifyOtp({required int userId, required String code});

  /// Reenvía el código OTP al correo del usuario.
  Future<void> resendOtp({required int userId});

  /// Inicia el flujo de recuperación de contraseña.
  Future<void> forgotPassword({required String email});

  /// Restablece la contraseña con el token del deep link.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  /// Cierra sesión en el servidor.
  Future<void> logout();

  /// Retorna los datos del usuario autenticado.
  Future<User> getMe();
}
