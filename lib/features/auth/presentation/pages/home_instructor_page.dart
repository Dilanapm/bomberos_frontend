import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class HomeInstructorPage extends ConsumerWidget {
  const HomeInstructorPage({super.key});

  Future<void> _checkAndNavigate({
    required BuildContext context,
    required WidgetRef ref,
    required bool Function(AuthState) hasPermission,
    required String moduleName,
    required VoidCallback onAllowed,
  }) async {
    // Momento 3: refrescar permisos antes de entrar al módulo
    await ref.read(authNotifierProvider.notifier).refreshMe();

    final authAsync = ref.read(authNotifierProvider);
    final allowed = authAsync.when(
      data:    (s) => hasPermission(s),
      loading: () => false,
      error:   (e, st) => false,
    );

    if (!context.mounted) return;

    if (allowed) {
      onAllowed();
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Acceso denegado'),
          content: Text(
            'No tienes permiso para acceder al módulo "$moduleName".\n'
            'Contacta al administrador para solicitar acceso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final authAsync = ref.watch(authNotifierProvider);

    final user = authAsync.when(
      data:    (s) => s is AuthAuthenticated ? s.user : null,
      loading: () => null,
      error:   (e, st) => null,
    );

    final canStats = user?.canViewStudentStats ?? false;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Instructor',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.instructor,
                  size: 80, color: AppColors.primary5),
              const SizedBox(height: 24),
              Text(
                'Panel del Instructor',
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí podrás generar y gestionar códigos de registro.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AppButton(
                label:    'Gestionar código de registro',
                onPressed: () => context.push(RouteNames.registrationCode),
              ),
              const SizedBox(height: 12),

              // ── Estadísticas de estudiantes ────────────────────────────────
              AppButton(
                label:   canStats
                    ? 'Estadísticas de estudiantes'
                    : 'Estadísticas de estudiantes  🔒',
                leading: Icon(
                  canStats
                      ? Icons.bar_chart_rounded
                      : Icons.lock_outline,
                  size: 20,
                  color: AppColors.white,
                ),
                onPressed: () => _checkAndNavigate(
                  context: context,
                  ref: ref,
                  hasPermission: (s) =>
                      s is AuthAuthenticated && s.user.canViewStudentStats,
                  moduleName: 'Estadísticas de estudiantes',
                  onAllowed: () => context.push(RouteNames.studentStats),
                ),
              ),
              const SizedBox(height: 12),

              AppButton(
                label:   'Mi perfil',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(RouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
