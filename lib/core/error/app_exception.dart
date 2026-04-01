/// Jerarquía de excepciones tipadas del dominio.
/// Todos los errores del sistema se mapean a estas clases antes de
/// llegar a la capa de presentación.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// ── Red / Conectividad ────────────────────────────────────────────────────────

/// Sin conexión a internet o timeout de red.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet.']);
}

/// El servidor tardó demasiado en responder.
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'La solicitud tardó demasiado.']);
}

// ── Autenticación / Autorización ─────────────────────────────────────────────

/// Token ausente o expirado (UNAUTHENTICATED).
class UnauthenticatedException extends AppException {
  const UnauthenticatedException(
      [super.message = 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.']);
}

/// Usuario existe pero el correo no ha sido verificado (EMAIL_NOT_VERIFIED).
class EmailNotVerifiedException extends AppException {
  const EmailNotVerifiedException({
    required this.userId,
    required this.email,
    String message = 'Debes verificar tu correo electrónico.',
  }) : super(message);

  final int userId;
  final String email;
}

/// Cuenta deshabilitada (ACCOUNT_DISABLED).
class AccountDisabledException extends AppException {
  const AccountDisabledException([super.message = 'Tu cuenta ha sido deshabilitada.']);
}

/// El usuario no tiene permisos para esta acción (ROLE_FORBIDDEN).
class RoleForbiddenException extends AppException {
  const RoleForbiddenException([super.message = 'No tienes permisos para esta acción.']);
}

// ── Validación / Negocio ─────────────────────────────────────────────────────

/// Errores de validación 422. [errors] mapea campo → lista de mensajes.
class ValidationException extends AppException {
  const ValidationException({
    required this.errors,
    String message = 'Por favor revisa los campos del formulario.',
  }) : super(message);

  final Map<String, List<String>> errors;
}

/// Credenciales inválidas, código incorrecto u otro error de negocio 4xx.
class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    required String message,
    this.code,
  }) : super(message);

  final int statusCode;
  final String? code;
}

// ── Rate Limit ────────────────────────────────────────────────────────────────

/// Demasiadas solicitudes (TOO_MANY_REQUESTS / 429).
class RateLimitException extends AppException {
  const RateLimitException(
      [super.message = 'Demasiadas solicitudes. Por favor espera un momento.']);
}

// ── Servidor ─────────────────────────────────────────────────────────────────

/// Error 5xx del servidor.
class ServerException extends AppException {
  const ServerException([super.message = 'Error del servidor. Intenta más tarde.']);
}

// ── Desconocido ───────────────────────────────────────────────────────────────

/// Cualquier error no previsto.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Ocurrió un error inesperado.']);
}
