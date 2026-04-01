import 'package:flutter/material.dart';

/// Ícono circular con fondo de color suave, adaptativo a light/dark.
///
/// Uso:
/// ```dart
/// AppIconBadge(icon: AppIcons.settings, color: AppColors.primary5)
/// ```
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final Color color;

  /// Tamaño del contenedor circular.
  final double size;

  /// Tamaño del ícono interior.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withAlpha(18)
            : color.withAlpha(25),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
