import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Convierte cualquier [DioException] en un [AppException] tipado.
class ErrorHandler {
  ErrorHandler._();

  static AppException handle(Object error) {
    if (error is AppException) return error; // ya fue procesado

    if (error is DioException) return _fromDio(error);

    return const UnknownException();
  }

  static AppException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _fromResponse(e.response);

      default:
        return UnknownException(e.message ?? 'Error desconocido.');
    }
  }

  static AppException _fromResponse(Response? response) {
    if (response == null) return const ServerException();

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Extraer campos del cuerpo estándar de la API
    final String message = _str(data, 'message') ?? 'Error desconocido.';
    final String? code = _str(data, 'code');

    // ── 422 Validación ────────────────────────────────────────────────────
    if (statusCode == 422) {
      final rawErrors = data?['errors'];
      final Map<String, List<String>> errors = {};
      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors[key.toString()] = value.map((v) => v.toString()).toList();
          }
        });
      }
      return ValidationException(errors: errors, message: message);
    }

    // ── 429 Rate limit ───────────────────────────────────────────────────
    if (statusCode == 429) return RateLimitException(message);

    // ── Códigos de error globales del dominio ────────────────────────────
    switch (code) {
      case 'UNAUTHENTICATED':
        return const UnauthenticatedException();
      case 'EMAIL_NOT_VERIFIED':
        final dataMap = data?['data'];
        final userId = (dataMap?['user_id'] as num?)?.toInt() ?? 0;
        final email = dataMap?['email']?.toString() ?? '';
        return EmailNotVerifiedException(userId: userId, email: email);
      case 'ACCOUNT_DISABLED':
        return AccountDisabledException(message);
      case 'ROLE_FORBIDDEN':
        return RoleForbiddenException(message);
      case 'TOO_MANY_REQUESTS':
        return RateLimitException(message);
    }

    // ── Por status code ──────────────────────────────────────────────────
    if (statusCode >= 500) return ServerException(message);

    return ApiException(statusCode: statusCode, message: message, code: code);
  }

  static String? _str(dynamic data, String key) {
    if (data is Map) return data[key]?.toString();
    return null;
  }
}
