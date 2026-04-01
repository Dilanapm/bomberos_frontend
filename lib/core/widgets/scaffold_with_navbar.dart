import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/route_names.dart';
import '../../app/theme/app_icons.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import 'app_navbar.dart';

/// Shell que proporciona un [bottomNavigationBar] persistente
/// según el rol del usuario. Se usa como builder del [ShellRoute].
class ScaffoldWithNavbar extends ConsumerWidget {
  const ScaffoldWithNavbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).asData?.value;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isInstructor = user?.role == 'instructor';

    return Scaffold(
      body: child,
      bottomNavigationBar: isInstructor
          ? AppNavBar(
              items: const [
                AppNavItem(
                  path:       RouteNames.homeInstructor,
                  icon:       AppIcons.homeOutlined,
                  activeIcon: AppIcons.home,
                  label:      'Inicio',
                ),
                AppNavItem(
                  path:       RouteNames.instructorTrainingSetup,
                  icon:       AppIcons.trainingOutlined,
                  activeIcon: AppIcons.training,
                  label:      'Entrenamiento',
                ),
                AppNavItem(
                  path:       RouteNames.studentStats,
                  icon:       AppIcons.statsOutlined,
                  activeIcon: AppIcons.stats,
                  label:      'Estadísticas',
                ),
                AppNavItem(
                  path:       RouteNames.profile,
                  icon:       AppIcons.profileOutlined,
                  activeIcon: AppIcons.profile,
                  label:      'Perfil',
                ),
              ],
            )
          : AppNavBar(
              items: const [
                AppNavItem(
                  path:       RouteNames.homeAprendiz,
                  icon:       AppIcons.homeOutlined,
                  activeIcon: AppIcons.home,
                  label:      'Inicio',
                ),
                AppNavItem(
                  path:       RouteNames.trainingInstructions,
                  icon:       AppIcons.trainingOutlined,
                  activeIcon: AppIcons.training,
                  label:      'Entrenamiento',
                ),
                AppNavItem(
                  path:       RouteNames.aprendizStats,
                  icon:       AppIcons.statsOutlined,
                  activeIcon: AppIcons.stats,
                  label:      'Estadísticas',
                ),
                AppNavItem(
                  path:       RouteNames.profile,
                  icon:       AppIcons.profileOutlined,
                  activeIcon: AppIcons.profile,
                  label:      'Perfil',
                ),
              ],
            ),
    );
  }
}
