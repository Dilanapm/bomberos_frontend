import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// AppBar reutilizable con estilo consistente para todas las pantallas
/// autenticadas. Adapta colores automáticamente al tema claro/oscuro.
///
/// Uso básico:
/// ```dart
/// appBar: AppAppBar(title: 'Mi pantalla'),
/// ```
///
/// Con colores personalizados (ej. pantallas de estadísticas):
/// ```dart
/// appBar: AppAppBar(
///   title: 'Estadísticas',
///   backgroundColor: AppColors.primary5,
///   foregroundColor: AppColors.white,
///   bottom: TabBar(...),
/// ),
/// ```
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.showDivider = true,
  });

  /// Texto del título. Si es null, no se muestra título.
  final String? title;

  /// Botones de acción en la derecha del AppBar.
  final List<Widget>? actions;

  /// Widget personalizado para el área izquierda (back button, etc.).
  /// Si es null, Flutter infiere el botón de retroceso automáticamente.
  final Widget? leading;

  /// Widget que aparece debajo del AppBar (ej. [TabBar]).
  /// Si se provee, el divisor se omite automáticamente.
  final PreferredSizeWidget? bottom;

  /// Color de fondo. Por defecto: white en light, dark1 en dark.
  final Color? backgroundColor;

  /// Color del ícono y texto. Por defecto: secondary900 en light, secondary50 en dark.
  final Color? foregroundColor;

  final bool centerTitle;

  /// Muestra un divisor sutil debajo del AppBar. Se ignora si se provee [bottom].
  final bool showDivider;

  bool get _showBuiltInDivider => showDivider && bottom == null;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight +
            (bottom?.preferredSize.height ?? 0) +
            (_showBuiltInDivider ? 1.0 : 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg =
        backgroundColor ?? (isDark ? AppColors.dark1 : AppColors.white);
    final effectiveFg =
        foregroundColor ?? (isDark ? AppColors.secondary50 : AppColors.secondary900);
    final dividerColor = isDark ? AppColors.dark3 : AppColors.secondary100;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: effectiveBg,
      foregroundColor: effectiveFg,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: leading == null,
      actions: actions,
      title: title != null
          ? Text(
              title!,
              style: textTheme.labelLarge?.copyWith(
                color: effectiveFg,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      bottom: _showBuiltInDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: dividerColor),
            )
          : bottom,
    );
  }
}
