import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/services/notifications_realtime_service.dart';
import '../../domain/entities/app_notification.dart';
import 'notifications_notifier.dart';
import 'unread_count_notifier.dart';

/// Provider de control que conecta/desconecta el servicio Reverb según el
/// estado de autenticación y reenvía los eventos a los notifiers de UI.
///
/// Se debe leer (`ref.read`) en `main` o en el shell raíz para que esté
/// activo durante toda la sesión.
final realtimeNotificationsProvider = Provider<RealtimeNotificationsController>(
  (ref) {
    final controller = RealtimeNotificationsController(ref);
    ref.onDispose(controller.dispose);
    controller.bindToAuth();
    return controller;
  },
);

class RealtimeNotificationsController {
  RealtimeNotificationsController(this._ref);

  final Ref _ref;
  ProviderSubscription<AsyncValue<AuthState>>? _authSub;
  StreamSubscription<RealtimeNotificationEvent>? _eventSub;

  void bindToAuth() {
    // Reaccionar a cada cambio del estado de auth.
    _authSub = _ref.listen<AsyncValue<AuthState>>(
      authNotifierProvider,
      (previous, next) {
        final auth = next.asData?.value;
        if (auth is AuthAuthenticated) {
          _start(auth.user.id);
        } else {
          _stop();
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _start(int userId) async {
    final storage = _ref.read(secureStorageProvider);
    final token   = await storage.readToken();
    if (token == null) return;

    try {
      await NotificationsRealtimeService.instance.connect(
        bearerToken: token,
        userId:      userId,
      );
    } catch (e) {
      debugPrint('[RealtimeController] connect failed: $e');
      return;
    }

    // Hidratar contador de no leídos.
    await _ref.read(unreadCountProvider.notifier).refresh();

    // Escuchar eventos del stream.
    _eventSub?.cancel();
    _eventSub = NotificationsRealtimeService.instance.events.listen(
      _onEvent,
    );
  }

  Future<void> _stop() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await NotificationsRealtimeService.instance.disconnect();
    _ref.read(unreadCountProvider.notifier).clear();
    // Invalidar la lista cacheada para que la próxima sesión no vea
    // notificaciones del usuario anterior.
    _ref.invalidate(notificationsProvider);
  }

  void _onEvent(RealtimeNotificationEvent event) {
    // Construir una notificación efímera para insertar en la lista.
    // El payload de Reverb no incluye un id de la tabla `notifications`,
    // por eso usamos un id sintético basado en timestamp + nombre.
    final id = 'rt-${DateTime.now().microsecondsSinceEpoch}-${event.eventName}';
    final type = _mapEventToType(event.eventName);
    DateTime created;
    final raw = event.data['created_at'] ?? event.data['reviewed_at'];
    if (raw is String) {
      created = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final notif = AppNotification(
      id:        id,
      type:      type,
      data:      event.data,
      read:      false,
      createdAt: created,
    );

    _ref.read(notificationsProvider.notifier).prependFromRealtime(notif);
    _ref.read(unreadCountProvider.notifier).increment();
  }

  String _mapEventToType(String eventName) {
    switch (eventName) {
      case 'evaluacion.guardada':
        return 'App\\Notifications\\EvaluacionGuardada';
      case 'evaluacion.revisada':
        return 'App\\Notifications\\EvaluacionRevisada';
      default:
        return eventName;
    }
  }

  void dispose() {
    _eventSub?.cancel();
    _authSub?.close();
    NotificationsRealtimeService.instance.disconnect();
  }
}
