import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/app_menu_card.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class HomeInstructorScreen extends ConsumerStatefulWidget {
  const HomeInstructorScreen({super.key});

  @override
  ConsumerState<HomeInstructorScreen> createState() =>
      _HomeInstructorScreenState();
}

class _HomeInstructorScreenState
    extends ConsumerState<HomeInstructorScreen> {

  /// Refresca /auth/me (Momento 3) y navega si tiene permiso.
  Future<void> _checkAndNavigate({
    required bool Function() hasPermission,
    required String moduleName,
    required VoidCallback onAllowed,
  }) async {
    await ref.read(authNotifierProvider.notifier).refreshMe();
    if (!mounted) return;
    if (hasPermission()) {
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).asData?.value;
    final user      = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.name.split(' ').first ?? 'Instructor';
    final canStats  = user?.canViewStudentStats ?? false;
    final canAi     = user?.canAccessAiModule   ?? false;

    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _Header(
              firstName: firstName,
              avatarUrl: user?.avatarUrl,
              isDark: isDark,
            ),

            

            // ── Contenido scrollable ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppMenuCard(
                      icon:     AppIcons.training,
                      title:    'Entrenamiento EPP',
                      subtitle: canAi
                          ? 'Iniciar sesión de práctica y evaluar colocación de equipo.'
                          : 'No tienes acceso al módulo de IA.',
                      locked:   !canAi,
                      onTap: () => _checkAndNavigate(
                        hasPermission: () {
                          final s = ref.read(authNotifierProvider).asData?.value;
                          return s is AuthAuthenticated && s.user.canAccessAiModule;
                        },
                        moduleName: 'Entrenamiento EPP (IA)',
                        onAllowed: () => context.push(RouteNames.instructorTrainingSetup),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppMenuCard(
                      icon:     AppIcons.group,
                      title:    'Agregar Aprendices',
                      subtitle: 'Genera un código de registro y compártelo '
                          'con tus nuevos aprendices.',
                      onTap:    () => context.push(RouteNames.registrationCode),
                    ),
                    const SizedBox(height: 12),
                    AppMenuCard(
                      icon:     AppIcons.analytics,
                      title:    'Estadísticas de Desempeño',
                      subtitle: canStats
                          ? 'Análisis detallado de resultados y métricas grupales.'
                          : 'No tienes acceso a este módulo.',
                      locked:   !canStats,
                      onTap: () => _checkAndNavigate(
                        hasPermission: () =>
                            (ref.read(authNotifierProvider).asData?.value
                                is AuthAuthenticated) &&
                            ((ref.read(authNotifierProvider).asData!.value
                                as AuthAuthenticated).user.canViewStudentStats),
                        moduleName: 'Estadísticas de Desempeño',
                        onAllowed: () => context.push(RouteNames.studentStats),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppMenuCard(
                      icon:     AppIcons.settingsOutlined,
                      title:    'Configuración',
                      subtitle: 'Ajustes de la aplicación y preferencias '
                          'del sistema.',
                      onTap:    () => context.push(RouteNames.profile),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.avatarUrl,
    required this.isDark,
  });

  final String firstName;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme     = Theme.of(context).textTheme;
    final textPrimary   = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final textSecondary = isDark ? AppColors.secondary300 : AppColors.secondary500;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Saludo ────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOMBEROS I',
                  style: textTheme.labelSmall?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hola, $firstName',
                  style: textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar con indicador online ───────────────────────────────────
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.dark3 : AppColors.secondary100,
                  border: Border.all(
                    color: isDark ? AppColors.dark4 : AppColors.secondary200,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) =>
                            _AvatarPlaceholder(isDark: isDark),
                      )
                    : _AvatarPlaceholder(isDark: isDark),
              ),
              // Punto verde online
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success700,
                    border: Border.all(
                      color: isDark ? AppColors.dark0 : AppColors.secondary50,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.profile,
      size: 26,
      color: isDark ? AppColors.secondary300 : AppColors.secondary400,
    );
  }
}