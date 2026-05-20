import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoadingMore = false,
    this.error,
  });

  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items:         items         ?? this.items,
      currentPage:   currentPage   ?? this.currentPage,
      lastPage:      lastPage      ?? this.lastPage,
      total:         total         ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error:         clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() => _loadPage(1, reset: true);

  Future<NotificationsState> _loadPage(int page, {bool reset = false}) async {
    final res = await ref
        .read(notificationsRepoProvider)
        .getPage(page: page);

    final previous = reset
        ? <AppNotification>[]
        : (state.asData?.value.items ?? const <AppNotification>[]);

    return NotificationsState(
      items:       [...previous, ...res.items],
      currentPage: res.currentPage,
      lastPage:    res.lastPage,
      total:       res.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(current.currentPage + 1);
      state = AsyncData(next);
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1, reset: true));
  }

  /// Marca una notificación como leída en el servidor y actualiza la lista.
  Future<void> markAsRead(String id) async {
    final current = state.asData?.value;
    if (current == null) return;
    final idx = current.items.indexWhere((n) => n.id == id);
    if (idx < 0 || current.items[idx].read) return;

    // Optimista: actualizar UI primero.
    final updated = [
      for (final n in current.items)
        if (n.id == id) n.copyWith(read: true, readAt: DateTime.now()) else n,
    ];
    state = AsyncData(current.copyWith(items: updated));

    try {
      await ref.read(notificationsRepoProvider).markAsRead(id);
    } catch (_) {
      // Si falla el server, no revertimos para no parpadear; el siguiente
      // refresh sincroniza el estado real.
    }
  }

  Future<void> markAllAsRead() async {
    final current = state.asData?.value;
    if (current == null) return;

    final now = DateTime.now();
    final updated = current.items
        .map((n) => n.read ? n : n.copyWith(read: true, readAt: now))
        .toList();
    state = AsyncData(current.copyWith(items: updated));

    try {
      await ref.read(notificationsRepoProvider).markAllAsRead();
    } catch (_) {}
  }

  /// Inserta una notificación al tope de la lista cuando llega por WebSocket.
  void prependFromRealtime(AppNotification incoming) {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.items.any((n) => n.id == incoming.id)) return;

    state = AsyncData(current.copyWith(
      items: [incoming, ...current.items],
      total: current.total + 1,
    ));
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
        NotificationsNotifier.new);
