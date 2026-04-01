import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Claves usadas en el almacenamiento seguro.
class _StorageKeys {
  static const token    = 'token';
  static const userRole = 'user_role';
  static const userId   = 'user_id';
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

  // ── Genérico (preferencias) ─────────────────────────────────────────────
  Future<void> writeRaw(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readRaw(String key) => _storage.read(key: key);

  // ── Limpiar ──────────────────────────────────────────────────────────────
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Provider global de [SecureStorage].
final secureStorageProvider = Provider<SecureStorage>((ref) {
  const storage = FlutterSecureStorage();
  return SecureStorage(storage);
});
