import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.data,
    required super.read,
    super.readAt,
    required super.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id:        json['id'] as String,
      type:      json['type'] as String,
      data:      Map<String, dynamic>.from(json['data'] as Map),
      read:      json['read'] as bool? ?? false,
      readAt:    json['read_at'] != null
                    ? DateTime.parse(json['read_at'] as String)
                    : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationPageModel extends NotificationPage {
  const NotificationPageModel({
    required super.items,
    required super.total,
    required super.perPage,
    required super.currentPage,
    required super.lastPage,
  });

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['notifications'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>;
    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.parse(v.toString());

    return NotificationPageModel(
      items:       list,
      total:       toInt(pagination['total']),
      perPage:     toInt(pagination['per_page']),
      currentPage: toInt(pagination['current_page']),
      lastPage:    toInt(pagination['last_page']),
    );
  }
}
