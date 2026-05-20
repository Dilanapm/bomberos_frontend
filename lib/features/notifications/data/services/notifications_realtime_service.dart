import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';

/// Evento entrante de Reverb. Se publica al stream del servicio.
class RealtimeNotificationEvent {
  const RealtimeNotificationEvent({
    required this.eventName,
    required this.data,
  });

  /// Por ejemplo: `evaluacion.guardada` o `evaluacion.revisada`.
  final String eventName;

  /// Payload JSON ya decodificado.
  final Map<String, dynamic> data;
}

/// Cliente del protocolo Pusher (compatible con Laravel Reverb) implementado
/// directamente sobre [WebSocketChannel].
///
/// El paquete oficial `pusher_channels_flutter` no permite apuntar a un host
/// auto-hospedado (solo Pusher Cloud), por lo que implementamos el subset
/// del protocolo que necesitamos: connection_established → /broadcasting/auth
/// → pusher:subscribe → escuchar eventos.
///
/// Singleton: `NotificationsRealtimeService.instance`.
class NotificationsRealtimeService {
  NotificationsRealtimeService._();
  static final NotificationsRealtimeService instance =
      NotificationsRealtimeService._();

  final StreamController<RealtimeNotificationEvent> _events =
      StreamController<RealtimeNotificationEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _pingTimer;

  String? _bearerToken;
  int? _userId;
  String? _socketId;
  String? _channelName;
  bool _connecting = false;

  Stream<RealtimeNotificationEvent> get events => _events.stream;
  bool get isConnected => _channel != null && _socketId != null;

  /// Conecta al servidor Reverb y se suscribe al canal privado del usuario.
  /// Si ya está conectado para el mismo usuario es no-op.
  Future<void> connect({
    required String bearerToken,
    required int userId,
  }) async {
    if (_connecting) return;
    if (isConnected && _userId == userId) return;
    if (_channel != null) await disconnect();

    _connecting   = true;
    _bearerToken  = bearerToken;
    _userId       = userId;
    _channelName  = 'private-App.Models.User.$userId';

    final scheme = Env.reverbUseTLS ? 'wss' : 'ws';
    final uri = Uri.parse(
      '$scheme://${Env.reverbHost}:${Env.reverbPort}/app/${Env.reverbAppKey}'
      '?protocol=7&client=flutter&version=1.0.0&flash=false',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _socketSub = _channel!.stream.listen(
        _onMessage,
        onError: (Object e, StackTrace st) {
          debugPrint('[Reverb] socket error: $e');
        },
        onDone: _onSocketDone,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[Reverb] connect failed: $e');
      _connecting = false;
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  /// Cierra el canal y detiene el ping.
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel      = null;
    _socketId     = null;
    _channelName  = null;
    _userId       = null;
    _bearerToken  = null;
  }

  // ── Mensajes entrantes del WebSocket ────────────────────────────────────────

  void _onMessage(dynamic raw) {
    Map<String, dynamic> message;
    try {
      message = (raw is String)
          ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
          : <String, dynamic>{};
    } catch (e) {
      debugPrint('[Reverb] decode error: $e — $raw');
      return;
    }

    final event = message['event']?.toString();
    final dataField = message['data'];

    Map<String, dynamic> payload;
    if (dataField is String) {
      try {
        final decoded = jsonDecode(dataField);
        payload = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
      } catch (_) {
        payload = <String, dynamic>{};
      }
    } else if (dataField is Map) {
      payload = Map<String, dynamic>.from(dataField);
    } else {
      payload = <String, dynamic>{};
    }

    switch (event) {
      case 'pusher:connection_established':
        _socketId = payload['socket_id']?.toString();
        _startPing();
        _subscribeToUserChannel();
        break;
      case 'pusher:error':
        debugPrint('[Reverb] pusher:error → $payload');
        break;
      case 'pusher:pong':
        // Sin acción — mantiene viva la conexión.
        break;
      case 'pusher_internal:subscription_succeeded':
      case 'pusher:subscription_succeeded':
        debugPrint('[Reverb] subscribed to ${message['channel']}');
        break;
      default:
        if (event != null && !event.startsWith('pusher')) {
          _events.add(RealtimeNotificationEvent(
            eventName: event,
            data:      payload,
          ));
        }
    }
  }

  void _onSocketDone() {
    debugPrint('[Reverb] socket closed');
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel   = null;
    _socketId  = null;
  }

  // ── Salida ─────────────────────────────────────────────────────────────────

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'pusher:ping', 'data': const <String, dynamic>{}});
    });
  }

  Future<void> _subscribeToUserChannel() async {
    final socketId = _socketId;
    final channel  = _channelName;
    final token    = _bearerToken;
    if (socketId == null || channel == null || token == null) return;

    final auth = await _authorize(channel, socketId, token);
    if (auth == null) return;

    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channel,
        'auth':    auth['auth'],
        if (auth['channel_data'] != null) 'channel_data': auth['channel_data'],
      },
    });
  }

  Future<Map<String, dynamic>?> _authorize(
    String channelName,
    String socketId,
    String token,
  ) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        Env.broadcastingAuthUrl,
        data: {
          'channel_name': channelName,
          'socket_id':    socketId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Client-Key':  Env.clientKey,
            'Content-Type':  'application/json',
            'Accept':        'application/json',
          },
        ),
      );
      final body = response.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      if (body is String) {
        return Map<String, dynamic>.from(jsonDecode(body) as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[Reverb] auth error: $e');
      return null;
    }
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[Reverb] send error: $e');
    }
  }
}
