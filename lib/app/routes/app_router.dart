import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_app_bar.dart';
import '../../core/widgets/scaffold_with_navbar.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/screens/home_aprendiz_screen.dart';
import '../../features/auth/presentation/screens/home_instructor_screen.dart';
import '../../features/epp_training/presentation/screens/epp_training_screen.dart';
import '../../features/epp_training/presentation/screens/instructor_aprendiz_selector_screen.dart';
import '../../features/auth/presentation/screens/camera_permission_screen.dart';
import '../../features/auth/presentation/screens/camera_session_screen.dart';
import '../../features/auth/presentation/screens/training_instructions_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/router_notifier.dart';
import '../../features/instructor/presentation/pages/registration_code_page.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/student_stats/presentation/screens/student_stats_screen.dart';
import '../../features/aprendiz_stats/presentation/screens/aprendiz_stats_screen.dart';
import '../../features/aprendiz_stats/presentation/screens/eval_detail_screen.dart';
import '../../features/instructor/presentation/screens/instructor_evaluations_screen.dart';
import '../../features/instructor/presentation/screens/instructor_eval_detail_screen.dart';
import '../../features/instructor/presentation/screens/instructor_student_evals_screen.dart';
import '../../features/profile/presentation/screens/security_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: RouteNames.welcome,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      _PermissionRefreshObserver(
        onPop: () => ref.read(authNotifierProvider.notifier).refreshMe(),
      ),
    ],

    // ── Splash / loading mientras se verifica la sesión ────────────────────
    // Cuando el authNotifierProvider está cargando, mostramos la bienvenida.

    routes: [
      // ── Públicas ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.welcome,
        builder: (ctx, st) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (ctx, st) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (ctx, st) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (ctx, st) => const ForgotPasswordPage(),
      ),

      // ── OTP (params anidados como extra) ──────────────────────────────────
      GoRoute(
        path: RouteNames.otp,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userId = extra?['userId'] as int? ?? 0;
          final email  = extra?['email']  as String? ?? '';
          return OtpPage(userId: userId, email: email);
        },
      ),

      // ── Reset password (desde deep link) ──────────────────────────────────
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (ctx, state) {
          final token = state.uri.queryParameters['token']
              ?? (state.extra as Map<String, dynamic>?)?['token'] as String?
              ?? '';
          final email = state.uri.queryParameters['email']
              ?? (state.extra as Map<String, dynamic>?)?['email'] as String?
              ?? '';
          return ResetPasswordPage(token: token, email: email);
        },
      ),

      // ── Protegidas CON navbar (ShellRoute) ────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => ScaffoldWithNavbar(child: child),
        routes: [
          GoRoute(
            path: RouteNames.homeInstructor,
            builder: (ctx, st) => const HomeInstructorScreen(),
          ),
          GoRoute(
            path: RouteNames.homeAprendiz,
            builder: (ctx, st) => const HomeAprendizScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (ctx, st) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.studentStats,
            builder: (ctx, st) => const StudentStatsScreen(),
          ),
          GoRoute(
            path: RouteNames.aprendizStats,
            builder: (ctx, st) => const AprendizStatsScreen(),
          ),
          GoRoute(
            path: RouteNames.aprendizEvalDetail,
            builder: (ctx, st) {
              final extra  = st.extra as Map<String, dynamic>?;
              final evalId = extra?['evalId'] as int? ?? 0;
              return EvalDetailScreen(evalId: evalId);
            },
          ),
          GoRoute(
            path: RouteNames.instructorEvaluations,
            builder: (ctx, st) => const InstructorEvaluationsScreen(),
          ),
          GoRoute(
            path: RouteNames.instructorStudentEvals,
            builder: (ctx, st) {
              final extra    = st.extra as Map<String, dynamic>?;
              final username = extra?['aprendizUsername'] as String? ?? '';
              final name     = extra?['aprendizName']     as String? ?? '';
              final avatar   = extra?['aprendizAvatar']   as String?;
              return InstructorStudentEvalsScreen(
                aprendizUsername: username,
                aprendizName:     name,
                aprendizAvatar:   avatar,
              );
            },
          ),
          GoRoute(
            path: RouteNames.instructorEvalDetail,
            builder: (ctx, st) {
              final extra  = st.extra as Map<String, dynamic>?;
              final evalId = extra?['evalId'] as int? ?? 0;
              return InstructorEvalDetailScreen(evalId: evalId);
            },
          ),
          GoRoute(
            path: RouteNames.trainingInstructions,
            builder: (ctx, st) => const TrainingInstructionsScreen(),
          ),
          GoRoute(
            path: RouteNames.instructorTrainingSetup,
            builder: (ctx, st) => const InstructorAprendizSelectorScreen(),
          ),
        ],
      ),

      // ── Protegidas SIN navbar (pantalla completa) ─────────────────────────
      GoRoute(
        path: RouteNames.registrationCode,
        builder: (ctx, st) => const RegistrationCodePage(),
      ),
      GoRoute(
        path: RouteNames.security,
        builder: (ctx, st) => const SecurityScreen(),
      ),
      GoRoute(
        path: RouteNames.aiModule,
        builder: (ctx, st) => _PlaceholderScreen(
          title: 'Módulo de IA',
          icon: Icons.smart_toy_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.cameraPermission,
        builder: (ctx, st) => const CameraPermissionScreen(),
      ),
      GoRoute(
        path: RouteNames.cameraSession,
        builder: (ctx, st) => const CameraSessionScreen(),
      ),
      GoRoute(
        path: RouteNames.eppTraining,
        builder: (ctx, st) => const EppTrainingScreen(),
      ),
    ],

    // ── Pantalla de error 404 ─────────────────────────────────────────────
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.uri}'),
      ),
    ),
  );
});

// ── Pantalla placeholder para módulos en desarrollo ──────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                title,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Este módulo está en desarrollo.\nEsperá las próximas actualizaciones.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Observer: refresca permisos solo al salir de cámara/EPP ──────────────────
// Solo dispara refreshMe() cuando se hace pop desde una pantalla que puede
// cambiar permisos del dispositivo, evitando llamadas a /auth/me en cada Back.
class _PermissionRefreshObserver extends NavigatorObserver {
  _PermissionRefreshObserver({required this.onPop});
  final VoidCallback onPop;

  static const _sensitiveRoutes = {
    RouteNames.cameraPermission,
    RouteNames.cameraSession,
    RouteNames.eppTraining,
  };

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name ?? '';
    if (_sensitiveRoutes.any((r) => name.startsWith(r))) {
      onPop();
    }
  }
}
