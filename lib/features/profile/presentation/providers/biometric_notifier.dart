import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

class BiometricState {
  const BiometricState({
    required this.availability,
    required this.isEnabled,
    this.isLoading = false,
    this.error,
  });

  final BiometricAvailability availability;

  /// Si el usuario activó el acceso biométrico.
  final bool isEnabled;

  /// Mientras se está autenticando o guardando la preferencia.
  final bool isLoading;

  /// Mensaje de error al intentar activar/desactivar.
  final String? error;

  bool get isAvailable => availability == BiometricAvailability.available;

  BiometricState copyWith({
    BiometricAvailability? availability,
    bool? isEnabled,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      BiometricState(
        availability: availability ?? this.availability,
        isEnabled:    isEnabled    ?? this.isEnabled,
        isLoading:    isLoading    ?? this.isLoading,
        error:        clearError   ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BiometricNotifier extends AsyncNotifier<BiometricState> {
  @override
  Future<BiometricState> build() async {
    final service = ref.read(biometricServiceProvider);
    final availability = await service.checkAvailability();
    final isEnabled    = await service.isEnabled();
    return BiometricState(
      availability: availability,
      isEnabled:    isEnabled,
    );
  }

  /// Activa o desactiva el acceso biométrico.
  ///
  /// Al activar, primero autentica al usuario para confirmar que el sensor
  /// funciona antes de guardar la preferencia.
  Future<void> toggle({required bool enable}) async {
    final current = state.value;
    if (current == null || current.isLoading) return;

    state = AsyncData(current.copyWith(isLoading: true, clearError: true));

    final service = ref.read(biometricServiceProvider);
    final storage = ref.read(secureStorageProvider);

    if (enable) {
      final authenticated = await service.authenticate(
        reason: 'Confirma tu identidad para activar el acceso biométrico',
      );
      if (!authenticated) {
        state = AsyncData(current.copyWith(isLoading: false));
        return;
      }
      // Guardar el token activo como token biométrico para futuro re-login.
      final token = await storage.readToken();
      if (token != null) {
        await storage.writeBiometricToken(token);
      }
    } else {
      // Al desactivar, eliminar el token biométrico guardado.
      await storage.deleteBiometricToken();
    }

    await service.setEnabled(value: enable);
    state = AsyncData(current.copyWith(isEnabled: enable, isLoading: false));
  }
}

final biometricNotifierProvider =
    AsyncNotifierProvider<BiometricNotifier, BiometricState>(
        BiometricNotifier.new);
