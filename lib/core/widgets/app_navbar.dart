import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import 'tap_scale.dart';

/// Modelo que describe un ítem del navbar.
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.path,
  });

  final IconData icon;

  /// Ícono que se muestra cuando el ítem está seleccionado.
  final IconData activeIcon;

  final String label;

  /// Ruta GoRouter a la que navegar con [context.go].
  /// Si es null, el ítem es no navegable (p. ej. aún sin implementar).
  final String? path;
}

/// Bottom navigation bar reutilizable y auto-sincronizado con GoRouter.
///
/// El ítem activo se calcula automáticamente a partir de la ruta actual via
/// [GoRouterState], por lo que cualquier cambio de pantalla (incluso el botón
/// Atrás del sistema) actualiza el navbar sin código extra en las pantallas.
///
/// Usa [context.go] para navegar (reemplaza el stack en lugar de apilar),
/// lo que evita la desincronización al regresar.
///
/// Uso:
/// ```dart
/// AppNavBar(
///   items: [
///     AppNavItem(path: RouteNames.home, icon: AppIcons.homeOutlined, activeIcon: AppIcons.home, label: 'Inicio'),
///     AppNavItem(path: RouteNames.profile, icon: AppIcons.profileOutlined, activeIcon: AppIcons.profile, label: 'Perfil'),
///   ],
/// )
/// ```
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
  }) : assert(items.length >= 2, 'AppNavBar requiere al menos 2 ítems');

  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final location  = GoRouterState.of(context).uri.path;

    // Calcula el ítem activo desde la ruta actual.
    // startsWith permite que sub-rutas como /profile/settings
    // sigan resaltando el ítem /profile.
    final selectedIndex = items.indexWhere(
      (item) =>
          item.path != null &&
          location.startsWith(item.path!),
    );

    final bgColor      = isDark ? AppColors.dark0  : AppColors.white;
    final borderColor  = isDark ? AppColors.dark2  : AppColors.secondary100;
    final inactiveColor = AppColors.secondary400;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final selected = selectedIndex == i;
              return _NavItem(
                icon:          selected ? item.activeIcon : item.icon,
                label:         item.label,
                selected:      selected,
                activeColor:   AppColors.primary5,
                inactiveColor: inactiveColor,
                onTap: item.path != null
                    ? () => context.go(item.path!)
                    : null,
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Ítem individual (privado) ──────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color     = selected ? activeColor : inactiveColor;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: TapScale(
          scaleDown: 0.88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


