import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icons.dart';
import 'app_icon_badge.dart';
import 'tap_scale.dart';

/// Fila de configuración con un [Switch.adaptive] a la derecha.
///
/// Uso:
/// ```dart
/// AppToggleTile(
///   icon: AppIcons.darkMode,
///   iconColor: AppColors.info400,
///   label: 'Modo Oscuro',
///   value: _isDark,
///   onChanged: (v) => setState(() => _isDark = v),
/// )
/// ```
class AppToggleTile extends StatelessWidget {
  const AppToggleTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final textTheme  = Theme.of(context).textTheme;
    final labelColor = isDark ? AppColors.secondary50 : AppColors.secondary700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary5,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor:
                isDark ? AppColors.dark4 : AppColors.secondary200,
          ),
        ],
      ),
    );
  }
}

/// Fila de configuración con un chevron (›) a la derecha, tappable.
///
/// Uso:
/// ```dart
/// AppChevronTile(
///   icon: AppIcons.security,
///   iconColor: AppColors.success600,
///   label: 'Seguridad',
///   onTap: () => _openSecurity(),
/// )
/// ```
class AppChevronTile extends StatelessWidget {
  const AppChevronTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  /// Texto secundario opcional debajo del label.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final textTheme    = Theme.of(context).textTheme;
    final labelColor   = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final subtitleColor = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final chevronColor = isDark ? AppColors.secondary400 : AppColors.secondary300;

    return TapScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            AppIconBadge(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 20, color: chevronColor),
          ],
        ),
      ),
    ),
    );
  }
}
