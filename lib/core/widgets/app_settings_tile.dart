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
    this.dense = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final textTheme  = Theme.of(context).textTheme;
    final labelColor = isDark ? AppColors.secondary50 : AppColors.secondary700;

    final vPad = dense ? 8.0 : 14.0;
    final badgeSize = dense ? 30.0 : 36.0;
    final badgeIcon = dense ? 16.0 : 18.0;
    final gap = dense ? 10.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
      child: Row(
        children: [
          AppIconBadge(
            icon: icon,
            color: iconColor,
            size: badgeSize,
            iconSize: badgeIcon,
          ),
          SizedBox(width: gap),
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
    this.dense = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  /// Texto secundario opcional debajo del label.
  final String? subtitle;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final textTheme    = Theme.of(context).textTheme;
    final labelColor   = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final subtitleColor = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final chevronColor = isDark ? AppColors.secondary400 : AppColors.secondary300;

    final vPad = dense ? 10.0 : 16.0;
    final badgeSize = dense ? 30.0 : 36.0;
    final badgeIcon = dense ? 16.0 : 18.0;
    final gap = dense ? 10.0 : 14.0;
    final chevronSize = dense ? 18.0 : 20.0;

    return TapScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
        child: Row(
          children: [
            AppIconBadge(
              icon: icon,
              color: iconColor,
              size: badgeSize,
              iconSize: badgeIcon,
            ),
            SizedBox(width: gap),
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
            Icon(AppIcons.chevronRight, size: chevronSize, color: chevronColor),
          ],
        ),
      ),
    ),
    );
  }
}
