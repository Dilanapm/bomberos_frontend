import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepository {
  const NotificationsRepository(this._ds);
  final NotificationsRemoteDataSource _ds;

  Future<NotificationPage> getPage({int page = 1, int perPage = 20}) =>
      _ds.fetchPage(page: page, perPage: perPage);

  Future<int> getUnreadCount() => _ds.fetchUnreadCount();

  Future<void> markAsRead(String id) => _ds.markAsRead(id);

  Future<void> markAllAsRead() => _ds.markAllAsRead();
}

final notificationsRepoProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(notificationsDsProvider));
});
