import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icons.dart';

/// Tarjeta de menú con ícono, título, descripción y chevron derecho.
///
/// Auto-detecta el modo claro/oscuro vía [Theme.of(context)].
///
/// Uso:
/// ```dart
/// AppMenuCard(
///   icon:     AppIcons.training,
///   title:    'Entrenamiento EPP',
///   subtitle: 'Iniciar sesión de práctica...',
///   onTap:    () {},
/// )
/// ```
///
/// Para un color de ícono personalizado por tarjeta pasa [iconColor].
class AppMenuCard extends StatelessWidget {
  const AppMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Color del ícono. Si es null se usa [AppColors.orange500] en claro
  /// y [AppColors.orange400] en oscuro.
  final Color? iconColor;

  /// Si [locked] es true, muestra un candado en lugar del chevron
  /// y opaca la tarjeta para indicar acceso restringido.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final cardBg         = isDark ? AppColors.cardDark   : AppColors.white;
    final titleColor     = isDark ? AppColors.secondary50 : AppColors.secondary700;
    final subtitleColor  = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final resolvedIcon   = iconColor ?? (isDark ? AppColors.orange400 : AppColors.orange500);
    final iconBg         = isDark
        ? Colors.white.withAlpha(18)
        : AppColors.iconBgLight.withAlpha(80);
    final chevronColor   = isDark ? AppColors.secondary400 : AppColors.secondary300;

    return Opacity(
      opacity: locked ? 0.55 : 1.0,
      child: Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // ── Ícono con fondo redondeado ───────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: resolvedIcon, size: 22),
              ),

              const SizedBox(width: 14),

              // ── Texto ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Chevron o candado ─────────────────────────────────────────
              Icon(
                locked ? Icons.lock_outline_rounded : AppIcons.chevronRight,
                color: locked
                    ? (isDark ? AppColors.secondary500 : AppColors.secondary400)
                    : chevronColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
