import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/app_notification_model.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<NotificationPageModel> fetchPage({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return NotificationPageModel.fromJson(data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final res = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final raw = data['unread_count'];
      return raw is num ? raw.toInt() : int.parse(raw.toString());
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.post(ApiEndpoints.notificationRead(id));
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.post(ApiEndpoints.notificationsReadAll);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final notificationsDsProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.read(dioClientProvider).dio);
});
