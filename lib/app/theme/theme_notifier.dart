import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage.dart';

const _kThemeKey = 'theme_mode';

/// Notifier que gestiona el [ThemeMode] de la aplicación y lo persiste
/// en almacenamiento seguro.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Cargar la preferencia guardada de forma asíncrona.
    _loadSaved();
    return ThemeMode.system;
  }

  SecureStorage get _storage => ref.read(secureStorageProvider);

  Future<void> _loadSaved() async {
    final saved = await _storage.readRaw(_kThemeKey);
    if (saved != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.writeRaw(_kThemeKey, mode.name);
  }

  /// Alterna entre claro y oscuro.
  /// Si actualmente es system, toma el brillo real y lo invierte.
  Future<void> toggle(Brightness currentBrightness) async {
    if (state == ThemeMode.dark || currentBrightness == Brightness.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

/// Provider global del modo de tema.
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
