import 'package:dio/dio.dart';
import '../config/env.dart';
import '../error/app_exception.dart';
import '../error/error_handler.dart';
import '../storage/secure_storage.dart';

/// Interceptor global que:
///  1. Agrega el header fijo `X-Client-Key`.
///  2. Agrega `Authorization: Bearer {token}` cuando haya sesión activa.
///  3. Convierte las respuestas de error en [AppException] tipadas.
///  4. Maneja los códigos globales del dominio (UNAUTHENTICATED, etc.).
class AppInterceptor extends Interceptor {
  AppInterceptor({
    required this.storage,
    this.onUnauthenticated,
    this.onEmailNotVerified,
    this.onAccountDisabled,
    this.onRoleForbidden,
  });

  final SecureStorage storage;

  /// Callback invocado cuando el servidor responde UNAUTHENTICATED.
  /// La capa superior (router / provider) se encarga de la navegación.
  final Future<void> Function()? onUnauthenticated;

  /// Callback invocado cuando el servidor responde EMAIL_NOT_VERIFIED.
  final Future<void> Function(int userId, String email)? onEmailNotVerified;

  /// Callback invocado cuando el servidor responde ACCOUNT_DISABLED.
  final Future<void> Function(String message)? onAccountDisabled;

  /// Callback invocado cuando el servidor responde ROLE_FORBIDDEN.
  final Future<void> Function()? onRoleForbidden;

  // ── Request ───────────────────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Header fijo para todos los requests
    options.headers['X-Client-Key'] = Env.clientKey;
    options.headers['Accept']       = 'application/json';

    // Token Bearer si existe
    final token = await storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  // ── Response ──────────────────────────────────────────────────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final appEx = ErrorHandler.handle(err);

    // Acciones globales según el tipo de excepción
    switch (appEx) {
      case UnauthenticatedException():
        await storage.deleteAll();
        await onUnauthenticated?.call();

      case EmailNotVerifiedException(:final userId, :final email):
        await onEmailNotVerified?.call(userId, email);

      case AccountDisabledException(:final message):
        await storage.deleteAll();
        await onAccountDisabled?.call(message);

      case RoleForbiddenException():
        await storage.deleteAll();
        await onRoleForbidden?.call();

      default:
        break;
    }

    // Siempre rechazamos con la excepción tipada para que los repos la capturen
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appEx,
        type: DioExceptionType.unknown,
      ),
    );
  }
}
