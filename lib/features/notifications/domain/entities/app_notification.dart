/// Tipos de notificación que conoce el cliente. Se usan para diferenciar
/// la UI (icono, color, acción al tocarla).
enum NotificationKind {
  evaluacionGuardada,
  evaluacionRevisada,
  unknown,
}

/// Una notificación recibida del backend (canal Reverb o GET /notifications).
///
/// El campo [data] es el payload tal como viene del servidor; los getters
/// convenientes cubren los campos comunes de los dos tipos conocidos.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  /// UUID generado por Laravel.
  final String id;

  /// Clase completa: `App\Notifications\EvaluacionGuardada`, etc.
  final String type;

  /// Payload entregado por el backend.
  final Map<String, dynamic> data;

  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  String? get message => data['message'] as String?;
  int? get evaluationId => (data['evaluation_id'] as num?)?.toInt();

  NotificationKind get kind {
    final t = data['type']?.toString();
    switch (t) {
      case 'evaluacion_guardada':
        return NotificationKind.evaluacionGuardada;
      case 'evaluacion_revisada':
        return NotificationKind.evaluacionRevisada;
      default:
        return NotificationKind.unknown;
    }
  }

  AppNotification copyWith({
    bool? read,
    DateTime? readAt,
  }) {
    return AppNotification(
      id:        id,
      type:      type,
      data:      data,
      read:      read   ?? this.read,
      readAt:    readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

/// Página paginada de notificaciones.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final List<AppNotification> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}
