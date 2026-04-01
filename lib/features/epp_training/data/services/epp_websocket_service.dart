import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';
import '../models/epp_classification_response.dart';

/// Servicio de WebSocket para clasificación EPP en tiempo real.
///
/// Gestiona la conexión con la API FastAPI, el envío de frames (JPEG en base64)
/// y la recepción de respuestas de clasificación.
///
/// - Limita el envío a 10 FPS para no saturar el servidor.
/// - Detecta la desconexión y notifica mediante [isConnected].
class EppWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<EppClassificationResponse> _responseController =
      StreamController<EppClassificationResponse>.broadcast();

  bool _isConnected = false;
  String? _sessionId;
  DateTime? _lastFrameSent;

  // ── Auth / identificación ─────────────────────────────────────────────────
  String? _authToken;
  String? _aprendizId;

  // ── Reconexión automática ─────────────────────────────────────────────────
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  // ── Pública ───────────────────────────────────────────────────────────────

  Stream<EppClassificationResponse> get responses => _responseController.stream;
  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;

  /// Conectar al endpoint WebSocket de FastAPI.
  ///
  /// - [authToken] : token de Sanctum que se incluirá en cada frame.
  /// - [aprendizId]: ID del aprendiz (solo cuando el instructor entrena a uno).
  Future<void> connect({
    String? sessionId,
    String? authToken,
    int? aprendizId,
  }) async {
    if (_isConnected) return;

    _sessionId  = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _authToken  = authToken;
    _aprendizId = aprendizId?.toString();

    try {
      final wsUrl = '${Env.fastApiWsUrl}/api/epp/classify/stream';
      debugPrint('[EPP WS] Conectando a $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('[EPP WS] ✅ Conectado (session=$_sessionId)');
    } catch (e) {
      _isConnected = false;
      debugPrint('[EPP WS] ❌ Error al conectar: $e');
      rethrow;
    }
  }

  // ── Envío de frames ───────────────────────────────────────────────────────

  /// Envía un [CameraImage] (convertido a JPEG) al servidor.
  /// Soporta formatos JPEG, BGRA8888 y YUV420.
  Future<void> sendCameraFrame(CameraImage image) async {
    if (!_isConnected) return;
    if (!_canSendFrame()) return;

    final jpeg = await _convertCameraImage(image);
    if (jpeg == null) return;

    _sendJpeg(jpeg);
  }

  /// Envía bytes JPEG crudos al servidor (para modo vídeo de prueba).
  void sendJpegBytes(Uint8List jpeg) {
    if (!_isConnected) return;
    if (!_canSendFrame()) return;
    _sendJpeg(jpeg);
  }

  // ── Desconexión ───────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    debugPrint('[EPP WS] Desconectando…');
    await _subscription?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
    _sessionId = null;
    _lastFrameSent = null;
    debugPrint('[EPP WS] ✅ Desconectado');
  }

  void dispose() {
    disconnect();
    _responseController.close();
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  bool _canSendFrame() {
    final now = DateTime.now();
    if (_lastFrameSent != null &&
        now.difference(_lastFrameSent!).inMilliseconds < 100) {
      return false; // Limitar a ~10 FPS
    }
    _lastFrameSent = now;
    return true;
  }

  void _sendJpeg(Uint8List jpeg) {
    try {
      final message = jsonEncode({
        'frame_base64': base64Encode(jpeg),
        'session_id': _sessionId,
        'fps': 10.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
        if (_authToken  != null) 'auth_token':  _authToken,
        if (_aprendizId != null) 'aprendiz_id': _aprendizId,
      });
      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('[EPP WS] Error enviando frame: $e');
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final response = EppClassificationResponse.fromJson(json);
      _responseController.add(response);
      debugPrint('[EPP WS] ${response.pasoNombre} '
          '(${(response.confianza * 100).toStringAsFixed(1)}%) '
          '${response.latenciaMs.toStringAsFixed(0)}ms');
    } catch (e) {
      debugPrint('[EPP WS] Error parseando respuesta: $e\nRaw: $raw');
    }
  }

  void _onError(Object error) {
    debugPrint('[EPP WS] Error en stream: $error');
    _isConnected = false;
    _tryReconnect();
  }

  void _onDone() {
    debugPrint('[EPP WS] Conexión cerrada por el servidor');
    _isConnected = false;
    _tryReconnect();
  }

  Future<void> _tryReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[EPP WS] Máximo de reconexiones alcanzado');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    debugPrint('[EPP WS] Reconectando en ${delay.inSeconds}s '
        '(intento $_reconnectAttempts/$_maxReconnectAttempts)…');
    await Future<void>.delayed(delay);
    try {
      await connect(
        sessionId: _sessionId,
        authToken: _authToken,
        aprendizId: _aprendizId != null ? int.tryParse(_aprendizId!) : null,
      );
    } catch (_) {
      // El siguiente intento lo maneja _onDone/_onError
    }
  }

  // ── Conversión de CameraImage ─────────────────────────────────────────────

  Future<Uint8List?> _convertCameraImage(CameraImage image) async {
    try {
      final format = image.format.group;

      // El emulador Android y algunos dispositivos devuelven JPEG directamente
      if (format == ImageFormatGroup.jpeg) {
        return image.planes[0].bytes;
      }

      // iOS: BGRA8888
      if (format == ImageFormatGroup.bgra8888) {
        return await compute(_bgra8888ToJpeg, _PlaneData.fromCamera(image));
      }

      // Android: YUV420 — conversión a escala de grises rápida para testing
      // TODO: implementar conversión YUV420 → color completo para producción
      if (format == ImageFormatGroup.yuv420) {
        return await compute(_yuv420GrayToJpeg, _PlaneData.fromCamera(image));
      }

      debugPrint('[EPP WS] Formato de imagen no soportado: $format');
      return null;
    } catch (e) {
      debugPrint('[EPP WS] Error convirtiendo frame: $e');
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Funciones top-level para compute() (no pueden ser métodos de instancia)
// ─────────────────────────────────────────────────────────────────────────────

/// Datos de plano serializables para pasar entre isolates.
class _PlaneData {
  final int width;
  final int height;
  final List<Uint8List> planes;
  final List<int> bytesPerRow;
  final List<int> bytesPerPixel;

  _PlaneData({
    required this.width,
    required this.height,
    required this.planes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  factory _PlaneData.fromCamera(CameraImage image) => _PlaneData(
        width: image.width,
        height: image.height,
        planes: image.planes.map((p) => p.bytes).toList(),
        bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
        bytesPerPixel:
            image.planes.map((p) => p.bytesPerPixel ?? 1).toList(),
      );
}

Uint8List _bgra8888ToJpeg(_PlaneData data) {
  final imgLib = img.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.planes[0].buffer,
    format: img.Format.uint8,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  return Uint8List.fromList(img.encodeJpg(imgLib, quality: 70));
}

/// Conversión YUV420 → JPEG usando solo el canal Y (escala de grises).
/// Suficiente para testing con el modelo de clasificación.
Uint8List _yuv420GrayToJpeg(_PlaneData data) {
  final w = data.width;
  final h = data.height;
  final yBytes = data.planes[0];
  final bpr = data.bytesPerRow[0];

  // Subsamplear a la mitad para velocidad
  final sw = w ~/ 2;
  final sh = h ~/ 2;

  final imgLib = img.Image(width: sw, height: sh, numChannels: 1);
  for (int row = 0; row < sh; row++) {
    for (int col = 0; col < sw; col++) {
      final yVal = yBytes[row * 2 * bpr + col * 2] & 0xFF;
      imgLib.setPixelRgb(col, row, yVal, yVal, yVal);
    }
  }
  return Uint8List.fromList(img.encodeJpg(imgLib, quality: 70));
}
