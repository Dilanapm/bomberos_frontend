import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/app_menu_card.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../notifications/presentation/providers/unread_count_notifier.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class HomeAprendizScreen extends ConsumerStatefulWidget {
  const HomeAprendizScreen({super.key});

  @override
  ConsumerState<HomeAprendizScreen> createState() =>
      _HomeAprendizScreenState();
}

class _HomeAprendizScreenState extends ConsumerState<HomeAprendizScreen> {

  /// Refresca /auth/me (Momento 3) y navega si tiene permiso,
  /// o muestra diálogo de acceso denegado.
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
            'Contacta a tu instructor para solicitar acceso.',
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
    final user = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.name.split(' ').first ?? 'Aprendiz';
    final canAi    = user?.canAccessAiModule    ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.dark0 : AppColors.secondary50,
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

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: AppScrollBody(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),

                    // ── Training card (gateada por canAccessAiModule) ─────────
                    GestureDetector(
                      onTap: () => _checkAndNavigate(
                        hasPermission: () {
                          final s = ref.read(authNotifierProvider).asData?.value;
                          return s is AuthAuthenticated && s.user.canAccessAiModule;
                        },
                        moduleName: 'Entrenamiento EPP (IA)',
                        onAllowed: () => context.push(RouteNames.trainingInstructions),
                      ),
                      child: _TrainingCard(isDark: isDark, locked: !canAi),
                    ),

                    const SizedBox(height: 20),

                    // ── Menu items ──────────────────────────────────────────
                    AppMenuCard(
                      icon:     AppIcons.statsOutlined,
                      title:    'Mis Estadísticas',
                      subtitle: 'Revisa tu rendimiento y progreso',
                      onTap:    () => _checkAndNavigate(
                        hasPermission: () {
                          final s = ref.read(authNotifierProvider).asData?.value;
                          return s is AuthAuthenticated &&
                              s.user.canAccessStatsModule;
                        },
                        moduleName: 'Mis Estadísticas',
                        onAllowed: () => context.push(RouteNames.aprendizStats),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppMenuCard(
                      icon:     AppIcons.settingsOutlined,
                      title:    'Configuración',
                      subtitle:
                          'Ajustes de la aplicación y preferencias del sistema.',
                      onTap:    () => context.push(RouteNames.profile),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (ctx, ref, _) {
                        final unread = ref.watch(unreadCountProvider);
                        final subtitle = unread == 0
                            ? 'Sin notificaciones nuevas'
                            : '$unread ${unread == 1 ? "notificación nueva" : "notificaciones nuevas"}';
                        return AppMenuCard(
                          icon:     AppIcons.notificationsOutlined,
                          title:    'Avisos',
                          subtitle: subtitle,
                          onTap:    () => context.push(RouteNames.notifications),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
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
    final textTheme = Theme.of(context).textTheme;
    final textPrimary =
        isDark ? AppColors.secondary50 : AppColors.secondary700;
    final textSecondary =
        isDark ? AppColors.secondary300 : AppColors.secondary500;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: textTheme.labelMedium?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
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

          const NotificationsBell(),
          const SizedBox(width: 12),

          // Avatar with online indicator — toca para ir a Perfil/Config
          GestureDetector(
            onTap: () => context.push(RouteNames.profile),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.dark3
                        : AppColors.secondary100,
                    border: Border.all(
                      color: isDark
                          ? AppColors.dark4
                          : AppColors.secondary200,
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
                // Online dot
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
                        color: isDark
                            ? AppColors.dark0
                            : AppColors.secondary50,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Training card
// ═══════════════════════════════════════════════════════════════════════════

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.isDark, this.locked = false});
  final bool isDark;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.dark4, AppColors.primary5]
              : [AppColors.primary4, AppColors.primary6],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              locked ? Icons.lock_outline_rounded : AppIcons.training,
              color: AppColors.white,
              size: 26,
            ),
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            locked ? 'Entrenamiento EPP — Acceso restringido' : 'Entrenamiento EPP',
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
