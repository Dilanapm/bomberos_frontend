/// Copia este archivo como `env.dart` en la misma carpeta y completa
/// los valores para tu entorno local.
///
/// IMPORTANTE:
/// - `env.dart` está ignorado por git y NO debe commitearse.
/// - Este archivo (`env.example.dart`) sí se versiona como plantilla.
class Env {
  Env._();

  // ── Laravel API ────────────────────────────────────────────────────────────
  // Emulador Android: http://10.0.2.2:8081/api/v1
  // Dispositivo físico: http://<IP_DE_TU_PC>:8081/api/v1
  static const String baseUrl = 'http://10.0.2.2:8081/api/v1';

  // Header requerido en TODAS las peticiones a /api/*: X-Client-Key
  // Debe coincidir con `API_CLIENT_KEY` del backend (Laravel .env).
  static const String clientKey = '<TU_API_CLIENT_KEY>'; // <- reemplaza

  // ── FastAPI - Clasificación EPP ─────────────────────────────────────────────
  // Emulador Android: http://10.0.2.2:8000 / ws://10.0.2.2:8000
  // Dispositivo físico: http://<IP_DE_TU_PC>:8000 / ws://<IP_DE_TU_PC>:8000
  static const String fastApiBaseUrl = 'http://10.0.2.2:8000';
  static const String fastApiWsUrl = 'ws://10.0.2.2:8000';
}
