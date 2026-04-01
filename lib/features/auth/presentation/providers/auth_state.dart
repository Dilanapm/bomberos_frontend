import '../../domain/entities/user.dart';

/// Estado de autenticación de la aplicación.
sealed class AuthState {
  const AuthState();
}

/// La app aún no sabe si hay sesión activa (al iniciar).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// El usuario está autenticado y sus datos están disponibles.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

/// No hay sesión activa o fue invalidada.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
