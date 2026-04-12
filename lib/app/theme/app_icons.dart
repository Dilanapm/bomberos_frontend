import 'package:flutter/material.dart';

/// Catálogo centralizado de iconos de la aplicación.
///
/// Todos los iconos usan el estilo **Rounded** de Material Symbols para
/// mantener coherencia visual en toda la app.
/// - Variante inactiva / outline → `*Outlined`
/// - Variante activa / filled   → `*`  (sin sufijo o con sufijo `rounded`)
///
/// Uso:
/// ```dart
/// Icon(AppIcons.home)           // activo
/// Icon(AppIcons.homeOutlined)   // inactivo / outline
/// ```
abstract final class AppIcons {
  // ── Navegación (navbar) ───────────────────────────────────────────────────
  static const IconData home         = Icons.home_rounded;
  static const IconData homeOutlined = Icons.home_outlined;

  static const IconData reports         = Icons.assignment_rounded;
  static const IconData reportsOutlined = Icons.assignment_outlined;

  static const IconData stats         = Icons.bar_chart_rounded;
  static const IconData statsOutlined = Icons.insert_chart_outlined_rounded;

  static const IconData profile         = Icons.person_rounded;
  static const IconData profileOutlined = Icons.person_outline_rounded;

  // ── Acciones generales ────────────────────────────────────────────────────
  static const IconData logout  = Icons.logout_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData copy    = Icons.copy_rounded;
  static const IconData add     = Icons.add_circle_outline_rounded;
  static const IconData delete  = Icons.delete_outline_rounded;
  static const IconData block   = Icons.block_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData edit    = Icons.edit_rounded;

  // ── Formularios ───────────────────────────────────────────────────────────
  static const IconData passwordVisible = Icons.visibility_rounded;
  static const IconData passwordHidden  = Icons.visibility_off_rounded;

  // ── Menú / opciones ───────────────────────────────────────────────────────
  static const IconData settings             = Icons.settings_rounded;
  static const IconData settingsOutlined     = Icons.settings_outlined;
  static const IconData notifications        = Icons.notifications_rounded;
  static const IconData notificationsOutlined = Icons.notifications_outlined;
  static const IconData darkMode             = Icons.dark_mode_rounded;
  static const IconData security             = Icons.lock_outline_rounded;
  static const IconData help                 = Icons.help_outline_rounded;

  // ── Entrenamiento / contenido ────────────────────────────────────────────
  static const IconData training         = Icons.fire_extinguisher_rounded;
  static const IconData trainingOutlined = Icons.fire_extinguisher_outlined;
  static const IconData instructor       = Icons.fire_truck_rounded;
  static const IconData aprendiz         = Icons.school_rounded;
  static const IconData qrCode           = Icons.qr_code_2_rounded;
  static const IconData analytics        = Icons.bar_chart_rounded;
  static const IconData group            = Icons.group_rounded;

  // ── Instrucciones de entrenamiento ─────────────────────────────────────
  static const IconData camera          = Icons.camera_alt_rounded;
  static const IconData lightbulb       = Icons.wb_sunny_rounded;
  static const IconData ruler            = Icons.straighten_rounded;
  static const IconData pose             = Icons.accessibility_new_rounded;
  static const IconData shield           = Icons.verified_user_outlined;

  // ── Búsqueda ──────────────────────────────────────────────────────────────
  // ── Evaluaciones ─────────────────────────────────────────────────────────────
  static const IconData evaluations         = Icons.assignment_rounded;
  static const IconData evaluationsOutlined = Icons.assignment_outlined;

  static const IconData search           = Icons.search_rounded;

  // ── Comunicación ─────────────────────────────────────────────────────────
  static const IconData email            = Icons.email_outlined;

  // ── Estado / feedback ────────────────────────────────────────────────────
  static const IconData error   = Icons.error_outline_rounded;
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData info    = Icons.info_outline_rounded;
}
