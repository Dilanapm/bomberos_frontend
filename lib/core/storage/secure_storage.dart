import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Claves usadas en el almacenamiento seguro.
class _StorageKeys {
  static const token             = 'token';
  static const userRole          = 'user_role';
  static const userId            = 'user_id';
  static const biometricEnabled  = 'biometric_enabled';
  /// Token preservado entre sesiones para el re-login biométrico.
  static const biometricToken    = 'biometric_token';
}

/// Wrapper sobre [FlutterSecureStorage] con métodos semánticos.
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // ── Token ────────────────────────────────────────────────────────────────
  Future<void> writeToken(String token) =>
      _storage.write(key: _StorageKeys.token, value: token);

  Future<String?> readToken() => _storage.read(key: _StorageKeys.token);

  // ── Rol ──────────────────────────────────────────────────────────────────
  Future<void> writeUserRole(String role) =>
      _storage.write(key: _StorageKeys.userRole, value: role);

  Future<String?> readUserRole() => _storage.read(key: _StorageKeys.userRole);

  // ── User ID ──────────────────────────────────────────────────────────────
  Future<void> writeUserId(int id) =>
      _storage.write(key: _StorageKeys.userId, value: id.toString());

  Future<int?> readUserId() async {
    final val = await _storage.read(key: _StorageKeys.userId);
    return val != null ? int.tryParse(val) : null;
  }

  // ── Biométrico ──────────────────────────────────────────────────────────
  Future<bool> readBiometricEnabled() async {
    final val = await _storage.read(key: _StorageKeys.biometricEnabled);
    return val == 'true';
  }

  Future<void> writeBiometricEnabled({required bool enabled}) =>
      _storage.write(
        key:   _StorageKeys.biometricEnabled,
        value: enabled.toString(),
      );

  // ── Token biométrico (persiste entre sesiones para re-login con huella) ──
  Future<void> writeBiometricToken(String token) =>
      _storage.write(key: _StorageKeys.biometricToken, value: token);

  Future<String?> readBiometricToken() =>
      _storage.read(key: _StorageKeys.biometricToken);

  Future<void> deleteBiometricToken() =>
      _storage.delete(key: _StorageKeys.biometricToken);

  // ── Genérico (preferencias) ─────────────────────────────────────────────
  Future<void> writeRaw(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readRaw(String key) => _storage.read(key: key);

  // ── Limpiar ──────────────────────────────────────────────────────────────

  /// Elimina **solo** los datos de sesión activa (token, rol, userId).
  /// Preserva [biometricEnabled] y [biometricToken] para permitir
  /// re-login con huella dactilar en la siguiente apertura.
  Future<void> deleteAuthData() => Future.wait([
    _storage.delete(key: _StorageKeys.token),
    _storage.delete(key: _StorageKeys.userRole),
    _storage.delete(key: _StorageKeys.userId),
  ]);

  Future<void> deleteAll() => _storage.deleteAll();
}

/// Provider global de [SecureStorage].
final secureStorageProvider = Provider<SecureStorage>((ref) {
  const storage = FlutterSecureStorage();
  return SecureStorage(storage);
});
