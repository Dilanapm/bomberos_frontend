import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'interceptors.dart';

/// Provider de la instancia [Dio] configurada.
///
/// Los callbacks globales de error (onUnauthenticated, etc.) se inyectan
/// desde authNotifierProvider después de que éste se inicializa, evitando
/// dependencias circulares. Por defecto son nulos; el [AppInterceptor] los
/// establece mediante [DioClient.setGlobalCallbacks].
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(storage: storage);
});

class DioClient {
  DioClient({required SecureStorage storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _interceptor = AppInterceptor(
      storage: storage,
      onUnauthenticated: () async => _onUnauthenticated?.call(),
      onEmailNotVerified: (id, email) async =>
          _onEmailNotVerified?.call(id, email),
      onAccountDisabled: (msg) async => _onAccountDisabled?.call(msg),
      onRoleForbidden: () async => _onRoleForbidden?.call(),
    );

    _dio.interceptors.add(_interceptor);

    // En debug, logear todas las peticiones y respuestas
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody:    true,
          responseBody:   true,
          requestHeader:  true,
          responseHeader: false,
          error:          true,
          logPrint: (o) => debugPrint('[DIO] $o'),
        ),
      );
    }
  }

  late final Dio _dio;
  late final AppInterceptor _interceptor;

  // Callbacks inyectados después de la init para evitar ciclos
  Future<void> Function()? _onUnauthenticated;
  Future<void> Function(int userId, String email)? _onEmailNotVerified;
  Future<void> Function(String message)? _onAccountDisabled;
  Future<void> Function()? _onRoleForbidden;

  Dio get dio => _dio;

  void setGlobalCallbacks({
    Future<void> Function()? onUnauthenticated,
    Future<void> Function(int userId, String email)? onEmailNotVerified,
    Future<void> Function(String message)? onAccountDisabled,
    Future<void> Function()? onRoleForbidden,
  }) {
    _onUnauthenticated    = onUnauthenticated;
    _onEmailNotVerified   = onEmailNotVerified;
    _onAccountDisabled    = onAccountDisabled;
    _onRoleForbidden      = onRoleForbidden;
  }
}
