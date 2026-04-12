import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/repositories/profile_repository_impl.dart';

/// Estado del provider de perfil.
class ProfileState {
  const ProfileState({required this.user, this.isLoading = false, this.error});
  final User user;
  final bool isLoading;
  final Object? error;

  ProfileState copyWith({User? user, bool? isLoading, Object? error}) {
    return ProfileState(
      user:      user      ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // ref.read: obtiene el usuario inicial sin suscribirse al stream completo.
    final authValue = ref.read(authNotifierProvider);
    final user = authValue.asData?.value is AuthAuthenticated
        ? (authValue.asData!.value as AuthAuthenticated).user
        : null;
    if (user == null) {
      throw StateError('ProfileNotifier requiere usuario autenticado.');
    }

    // ref.listen: actualiza solo user.name/avatar cuando auth cambia
    // (ej. después de editar el perfil), sin reconstruir todo el notifier.
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      final updated = next.asData?.value;
      if (updated is AuthAuthenticated) {
        state = state.copyWith(user: updated.user);
      }
    });

    return ProfileState(user: user);
  }

  Future<void> updateProfile({String? name, String? username}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await ref.read(profileRepositoryProvider).updateProfile(
            name: name, username: username);
      state = state.copyWith(isLoading: false, user: updated);
      // Sincronizar con el estado global de auth
      _syncAuthState(updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword:      currentPassword,
            password:             password,
            passwordConfirmation: passwordConfirmation,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> uploadAvatar(File file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated =
          await ref.read(profileRepositoryProvider).uploadAvatar(file);
      state = state.copyWith(isLoading: false, user: updated);
      _syncAuthState(updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(profileRepositoryProvider).deleteAvatar();
      final updated = state.user.copyWith(avatarUrl: null);
      state = state.copyWith(isLoading: false, user: updated);
      _syncAuthState(updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  void _syncAuthState(User user) {
    ref.read(authNotifierProvider.notifier).updateUser(user);
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
