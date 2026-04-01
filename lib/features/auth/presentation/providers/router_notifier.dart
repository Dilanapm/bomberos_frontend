import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Puente entre [authNotifierProvider] y [GoRouter].
/// Implementa [Listenable] para que GoRouter se actualice cuando cambia
/// el estado de autenticación.
class RouterNotifier extends Notifier<void> implements Listenable {
  final _listeners = <VoidCallback>[];

  @override
  void build() {
    // Observar el estado de auth y notificar a GoRouter cuando cambie
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      _notifyAll();
    });
  }

  void _notifyAll() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Lógica de redirección centralizada.
  String? redirect(BuildContext context, GoRouterState routerState) {
    final authAsync = ref.read(authNotifierProvider);

    return authAsync.when(
      loading: () => null, // No redirigir mientras carga
      error:   (err, st) => null, // La página maneja su propio error vía ref.listen
      data:    (auth) => _resolveRedirect(auth, routerState.matchedLocation),
    );
  }

  String? _resolveRedirect(AuthState auth, String currentLocation) {
    final isOnPublicRoute = RouteNames.publicRoutes.contains(currentLocation) ||
        currentLocation.startsWith(RouteNames.otp) ||
        currentLocation.startsWith(RouteNames.resetPassword);

    switch (auth) {
      case AuthLoading():
        return null;

      case AuthAuthenticated(:final user):
        // Si está en ruta pública, redirigir a home según rol
        if (isOnPublicRoute) {
          return user.isInstructor
              ? RouteNames.homeInstructor
              : RouteNames.homeAprendiz;
        }
        return null;

      case AuthUnauthenticated():
        // Si está en ruta protegida, redirigir a login
        if (!isOnPublicRoute &&
            !RouteNames.alwaysPublicRoutes.contains(currentLocation)) {
          return RouteNames.login;
        }
        return null;
    }
  }
}

final routerNotifierProvider =
    NotifierProvider<RouterNotifier, void>(RouterNotifier.new);
