# Notificaciones en Tiempo Real — Flutter

## Arquitectura

```
Flutter ──WebSocket──▶ Reverb (puerto 8080)
Flutter ──HTTP──────▶ Laravel API (puerto 8081)
                          │
                    PostgreSQL (tabla notifications)
```

**Stack:**
- Laravel Reverb: servidor WebSocket (protocolo Pusher)
- Canal privado por usuario: `private-App.Models.User.{id}`
- Persistencia en PostgreSQL (`notifications` table)
- Queue: notificaciones se envían de forma asíncrona

---

## Instalación Flutter

```yaml
# pubspec.yaml
dependencies:
  pusher_channels_flutter: ^2.1.0
```

```bash
flutter pub get
```

---

## Configuración de Reverb

| Variable | Valor |
|---|---|
| Host | IP del servidor (ej: `10.196.39.27`) |
| Puerto WebSocket | `8080` |
| App Key | `bomberos-key-2026` |
| Cluster | `mt1` (cualquier valor, Reverb lo ignora) |
| TLS | `false` (HTTP en desarrollo) |

---

## Implementación Flutter

### 1. Servicio de Notificaciones

```dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late PusherChannelsFlutter _pusher;
  PusherChannel? _privateChannel;
  bool _connected = false;

  // Callbacks para la UI
  void Function(Map<String, dynamic>)? onEvaluacionGuardada;
  void Function(Map<String, dynamic>)? onEvaluacionRevisada;

  Future<void> init({
    required String serverHost,  // IP del servidor
    required String bearerToken, // Token Sanctum del usuario logueado
    required int userId,
  }) async {
    _pusher = PusherChannelsFlutter.getInstance();

    await _pusher.init(
      apiKey: 'bomberos-key-2026',
      cluster: 'mt1',
      wsHost: serverHost,
      wsPort: 8080,
      wssPort: 8080,
      useTLS: false,
      // URL de autenticación de canal privado
      authEndpoint: 'http://$serverHost:8081/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        // Necesitamos llamar al endpoint con el token Sanctum
        return await _authorize(channelName, socketId, bearerToken, serverHost);
      },
      onConnectionStateChange: (currentState, previousState) {
        _connected = currentState == 'CONNECTED';
      },
      onError: (message, code, error) {
        print('Pusher error: $message');
      },
    );

    await _pusher.connect();
    await _subscribeToUserChannel(userId);
  }

  Future<dynamic> _authorize(
    String channelName,
    String socketId,
    String token,
    String host,
  ) async {
    final dio = Dio(); // o http.Client
    final response = await dio.post(
      'http://$host:8081/broadcasting/auth',
      data: {
        'channel_name': channelName,
        'socket_id': socketId,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'X-Client-Key': 'TU_API_CLIENT_KEY',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }),
    );
    return response.data;
  }

  Future<void> _subscribeToUserChannel(int userId) async {
    final channelName = 'private-App.Models.User.$userId';

    _privateChannel = await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        final data = jsonDecode(event.data as String) as Map<String, dynamic>;
        _handleEvent(event.eventName, data);
      },
    );
  }

  void _handleEvent(String eventName, Map<String, dynamic> data) {
    switch (eventName) {
      case 'evaluacion.guardada':
        onEvaluacionGuardada?.call(data);
        break;
      case 'evaluacion.revisada':
        onEvaluacionRevisada?.call(data);
        break;
    }
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
    _connected = false;
  }
}
```

### 2. Usar el Servicio (tras login)

```dart
// En el AuthController / main después del login:
await NotificationService().init(
  serverHost: '10.196.39.27',
  bearerToken: authToken,          // Token devuelto por /api/v1/auth/login
  userId: currentUser.id,
);

// Configurar callbacks
NotificationService().onEvaluacionGuardada = (data) {
  // data: { type, evaluation_id, status, general_score, message, created_at }
  showSnackbar(data['message']);
  // Actualizar lista de evaluaciones
};

NotificationService().onEvaluacionRevisada = (data) {
  // data: { type, evaluation_id, instructor_name, instructor_final_score, message, reviewed_at }
  showDialog(title: 'Revisión de instructor', message: data['message']);
};
```

### 3. Cerrar conexión al hacer logout

```dart
await NotificationService().disconnect();
```

---

## API REST de Notificaciones (historial + marcado como leído)

Base URL: `http://{host}:8081/api/v1`

Headers requeridos en todas las peticiones:
```
Authorization: Bearer {token}
X-Client-Key: {API_CLIENT_KEY}
Accept: application/json
```

---

### GET /notifications

Lista paginada de notificaciones del usuario autenticado.

**Query params:**
- `page` (int, opcional, default: 1)
- `per_page` (int, opcional, default: 20, max: 50)

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "uuid-123",
        "type": "App\\Notifications\\EvaluacionGuardada",
        "data": {
          "type": "evaluacion_guardada",
          "evaluation_id": 42,
          "status": "aprobado",
          "general_score": 87.5,
          "message": "¡Felicidades! Aprobaste con 87.5%.",
          "created_at": "2026-04-27T10:30:00+00:00"
        },
        "read": false,
        "read_at": null,
        "created_at": "2026-04-27T10:30:05+00:00"
      }
    ],
    "pagination": {
      "total": 15,
      "per_page": 20,
      "current_page": 1,
      "last_page": 1
    }
  }
}
```

---

### GET /notifications/unread-count

Cantidad de notificaciones no leídas (útil para badge en UI).

**Response:**
```json
{
  "success": true,
  "data": {
    "unread_count": 3
  }
}
```

---

### POST /notifications/{id}/read

Marca una notificación específica como leída.

**Response:**
```json
{
  "success": true,
  "message": "Notificación marcada como leída."
}
```

---

### POST /notifications/read-all

Marca todas las notificaciones como leídas.

**Response:**
```json
{
  "success": true,
  "message": "Todas las notificaciones marcadas como leídas."
}
```

---

## Tipos de Eventos WebSocket

### `evaluacion.guardada`
Se emite cuando un instructor guarda una evaluación para el aprendiz.

```json
{
  "type": "evaluacion_guardada",
  "evaluation_id": 42,
  "status": "aprobado",
  "general_score": 87.5,
  "message": "¡Felicidades! Aprobaste con 87.5%.",
  "created_at": "2026-04-27T10:30:00+00:00"
}
```

### `evaluacion.revisada`
Se emite cuando el instructor registra su criterio final (`/review`).

```json
{
  "type": "evaluacion_revisada",
  "evaluation_id": 42,
  "instructor_name": "Prof. García",
  "instructor_final_score": 90.0,
  "message": "Tu instructor Prof. García revisó tu evaluación. Puntaje final: 90%.",
  "reviewed_at": "2026-04-27T14:00:00+00:00"
}
```

---

## Comandos Docker para activar Reverb

```bash
# 1. Instalar Reverb (solo primera vez)
docker compose exec app composer require laravel/reverb

# 2. Publicar configuración
docker compose exec app php artisan reverb:install

# 3. Correr la migración de notifications
docker compose exec app php artisan migrate

# 4. Reiniciar con el nuevo servicio reverb
docker compose up -d reverb
```

> **Nota:** El servicio `reverb` ya está en `docker-compose.yml`. Solo necesitas ejecutar los comandos anteriores.
