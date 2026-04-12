import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../storage/secure_storage.dart';

/// Resultado de la verificación de disponibilidad biométrica.
enum BiometricAvailability {
  /// Hardware presente y biométricos enrollados.
  available,

  /// El dispositivo no tiene sensor biométrico.
  noHardware,

  /// Hay hardware pero el usuario no tiene biométricos registrados.
  notEnrolled,

  /// No disponible (passcode deshabilitado, error desconocido, etc.).
  unavailable,
}

/// Servicio centralizado para autenticación biométrica.
///
/// Encapsula [LocalAuthentication] y [SecureStorage] para:
/// 1. Detectar si el dispositivo soporta biometría.
/// 2. Lanzar el prompt nativo de autenticación.
/// 3. Persistir/leer la preferencia del usuario.
class BiometricService {
  BiometricService(this._auth, this._storage);

  final LocalAuthentication _auth;
  final SecureStorage _storage;

  // ── Disponibilidad ────────────────────────────────────────────────────────

  /// Devuelve el nivel de disponibilidad biométrica del dispositivo.
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!isDeviceSupported) return BiometricAvailability.noHardware;
      if (!canCheck) return BiometricAvailability.notEnrolled;

      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return BiometricAvailability.notEnrolled;

      return BiometricAvailability.available;
    } catch (e) {
      debugPrint('[BiometricService] checkAvailability error: $e');
      return BiometricAvailability.unavailable;
    }
  }

  // ── Autenticación ─────────────────────────────────────────────────────────

  /// Lanza el prompt nativo de biometría.
  ///
  /// Devuelve `true` si el usuario se autenticó correctamente,
  /// `false` si canceló o falló.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth:  true,
          biometricOnly: false, // permite PIN como fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Preferencia guardada ─────────────────────────────────────────────────

  Future<bool> isEnabled() => _storage.readBiometricEnabled();

  Future<void> setEnabled({required bool value}) =>
      _storage.writeBiometricEnabled(enabled: value);
}

/// Provider global de [BiometricService].
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(
    LocalAuthentication(),
    ref.read(secureStorageProvider),
  );
});
