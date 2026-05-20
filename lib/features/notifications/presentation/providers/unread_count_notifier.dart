import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';

/// Contador de notificaciones no leídas (badge en UI).
///
/// Estado expuesto como [int]; arranca en 0 y se hidrata con
/// [refresh()] tras login. Las notificaciones entrantes por WebSocket
/// llaman [increment()] para no esperar al GET.
class UnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refresh() async {
    try {
      final count = await ref
          .read(notificationsRepoProvider)
          .getUnreadCount();
      state = count;
    } catch (_) {
      // No bloqueamos UI por un error de red.
    }
  }

  void increment() => state = state + 1;

  void decrement() {
    if (state > 0) state = state - 1;
  }

  void clear() => state = 0;

  void reset() => state = 0;
}

final unreadCountProvider =
    NotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);
