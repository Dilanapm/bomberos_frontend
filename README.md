# Bomberos Frontend (Flutter)

Frontend mobile/web para el sistema de apoyo al entrenamiento de bomberos.
Este cliente consume APIs de backend para autenticacion, gestion de perfiles,
entrenamiento y estadisticas por rol (instructor / aprendiz).

## 1. Que hace este frontend

- Gestiona autenticacion completa (login, registro, OTP, recuperacion de clave).
- Maneja sesion y permisos por rol.
- Muestra home distinto para instructor y aprendiz.
- Ejecuta flujo de entrenamiento con pantallas dedicadas.
- Integra evaluacion EPP con servicio FastAPI (HTTP + WebSocket).
- Presenta modulo de estadisticas para aprendiz e instructor.
- Genera reportes PDF de estadisticas del aprendiz.
- Soporta tema claro/oscuro persistido en almacenamiento seguro.

## 2. Objetivo del proyecto en este punto

El objetivo actual es consolidar una experiencia estable por rol:

- Instructor:
  - Gestion de codigo de registro de aprendices.
  - Vista de estadisticas de estudiantes/grupo.
  - Entrada al flujo de entrenamiento de instructor.
- Aprendiz:
  - Flujo de entrenamiento individual.
  - Estadisticas personales y detalle de evaluaciones.
  - Exportacion de reportes PDF.

Estado actual relevante:

- Navbar centralizado con ShellRoute para evitar duplicacion.
- Navegacion de navbar separada por rol.
- Entrenamiento inicial por rol dentro del ShellRoute.
- Pantallas de camara/EPP fuera del ShellRoute (full screen).
- Modulo de IA general todavia en placeholder.

## 3. Stack tecnico

- Flutter (Material 3)
- Riverpod (estado/inyeccion)
- GoRouter (navegacion + redirect por auth)
- Dio (cliente HTTP + interceptores)
- flutter_secure_storage (token, rol, userId, preferencias)
- camera, permission_handler, image_picker, video_player
- web_socket_channel (stream de clasificacion EPP)
- pdf, printing, share_plus (reportes)

## 4. Conexion con backends

### 4.1 Laravel API (principal)

Configurada en `lib/core/config/env.dart` (archivo local, NO se commitea):

- `Env.baseUrl` -> API principal (`/api/v1`)
- `Env.clientKey` -> header fijo `X-Client-Key`

El cliente HTTP global esta en `lib/core/network/dio_client.dart` y usa:

- `Authorization: Bearer <token>` si hay sesion
- `X-Client-Key` en todas las requests
- Interceptor global para mapear errores de dominio

### 4.2 FastAPI (EPP)

Tambien en `lib/core/config/env.dart`:

- `Env.fastApiBaseUrl` (HTTP)
- `Env.fastApiWsUrl` (WebSocket)

Uso principal:

- Evaluacion HTTP EPP: `POST /api/epp/evaluate`
- Stream WebSocket EPP: `/api/epp/classify/stream`

## 5. Rutas y navegacion

Definidas en `lib/app/routes/route_names.dart` y `lib/app/routes/app_router.dart`.

- Publicas: welcome, login, register, forgot-password, otp, reset-password.
- Protegidas con navbar (ShellRoute):
  - home instructor/aprendiz
  - profile
  - student stats
  - aprendiz stats + detalle
  - training instructions
  - instructor training setup
- Protegidas sin navbar (full screen):
  - registration code
  - ai module (placeholder)
  - camera permission/session
  - epp training

Navbar persistente por rol: `lib/core/widgets/scaffold_with_navbar.dart`.

## 6. Modulos funcionales principales

### 6.1 Auth + Perfil

- Login/registro/OTP/reset.
- Perfil editable y cambio de password.
- Refresco de permisos al volver a foreground.

### 6.2 Entrenamiento

- Flujo de instrucciones y preparacion.
- Permisos y sesion de camara.
- Entrenamiento EPP con analisis remoto.
- Setup de entrenamiento para instructor.

### 6.3 Estadisticas aprendiz

- Dashboard resumen.
- Analitica avanzada.
- Historial paginado.
- Detalle de evaluacion.
- Exportacion PDF (resumen, analisis, historial).

### 6.4 Estadisticas instructor

- Resumen del grupo.
- Ranking de aprendices.
- Deteccion de aprendices que requieren apoyo.
- Analisis por paso del protocolo.

## 7. Arquitectura (carpetas)

El proyecto sigue una organizacion por features con capas:

- `lib/app`: bootstrap, rutas, tema.
- `lib/core`: config, red, errores, storage, widgets comunes.
- `lib/features/<feature>`:
  - `data`: datasources/models/repositories
  - `domain`: entities/repositories
  - `presentation`: screens/pages/providers/widgets/services

## 8. Tema visual: reglas obligatorias para frontend

Para mantener consistencia del producto, toda UI nueva debe respetar estas reglas.

### 8.1 Colores

Fuente unica de verdad: `lib/app/theme/app_colors.dart`.

- Color principal de marca: `AppColors.primary5` (`#AA241D`).
- No hardcodear colores en widgets si existe token en `AppColors`.
- Priorizar `colorScheme` del theme para componentes Material.

### 8.2 Tipografia

Fuente base definida en `pubspec.yaml` + `lib/app/theme/app_typography.dart`.

- Familia oficial: `Inter`.
- Usar `Theme.of(context).textTheme`.
- No definir tamanos/pesos arbitrarios si ya existen tokens tipograficos.

### 8.3 Tema claro/oscuro

- Definido en `lib/app/theme/app_theme.dart`.
- Estado persistido por `theme_notifier.dart` en secure storage.
- Evitar estilos que rompan contraste en dark mode.

### 8.4 Navbar y navegacion

- No duplicar navbar por pantalla.
- Las pantallas con navegacion base deben vivir dentro de ShellRoute.
- Pantallas inmersivas (camara, flujo full-screen) pueden ir fuera.

## 9. Endpoints relevantes (resumen)

En `lib/core/network/api_endpoints.dart`:

- Auth: `/auth/login`, `/auth/register`, `/auth/me`, etc.
- Perfil: `/profile`, `/profile/password`, `/profile/avatar`
- Instructor:
  - `/instructor/registration-code`
  - `/instructor/registration-code/active`
  - `/instructor/stats/my-group`
  - `/instructor/stats/ranking`
  - `/instructor/stats/need-help`
  - `/instructor/stats/step-analysis`
- Aprendiz stats:
  - `/evaluations/stats`
  - `/evaluations/analytics`
  - `/evaluations`

## 10. Configuracion local rapida

1. Instalar dependencias:

```bash
flutter pub get
```

2. Crear tu configuración local (no se sube a GitHub):

- Copia `lib/core/config/env.example.dart` → `lib/core/config/env.dart`
- Edita `Env.baseUrl`, `Env.fastApiBaseUrl`, `Env.fastApiWsUrl` y `Env.clientKey`

3. Ejecutar:

```bash
flutter run
```

## 11. Convenciones importantes para nuevos cambios

- Mantener separacion por capas (presentation/domain/data).
- Reusar `dioClientProvider` y no crear clientes HTTP sueltos.
- Manejar parseo defensivo de numericos cuando backend pueda devolver strings.
- Para nuevas pantallas, priorizar componentes de `core/widgets`.
- Si agregas una ruta principal, validar si debe ir dentro o fuera del ShellRoute.

## 12. Resumen para un nuevo chat

Si comienzas un chat nuevo, este es el contexto minimo:

- Proyecto Flutter para entrenamiento de bomberos con 2 roles.
- Conecta a Laravel (auth/perfiles/estadisticas) y FastAPI (EPP).
- Navbar ya esta centralizado con ShellRoute y rutas por rol.
- Tema (colores/fuente/dark mode) ya esta definido y debe respetarse.
- Modulo de estadisticas (aprendiz + instructor) esta implementado.
- PDFs de estadisticas del aprendiz estan implementados.
- El siguiente trabajo suele enfocarse en pulir flujos de entrenamiento,
  cerrar placeholders y mantener coherencia visual/arquitectonica.
