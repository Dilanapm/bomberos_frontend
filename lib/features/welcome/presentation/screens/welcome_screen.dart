import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: Stack(
        children: [
          // ── Red gradient glow at the top ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.40,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Logo ─────────────────────────────────────────────────
                  Container(
                    width: 148,
                    height: 148,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.logoOverlay,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Title ─────────────────────────────────────────────────
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.secondary50,
                        height: 1.25,
                      ),
                      children: const [
                        TextSpan(text: 'Sistema de\n'),
                        TextSpan(
                          text: 'Entrenamiento\n',
                          style: TextStyle(color: AppColors.primary5),
                        ),
                        TextSpan(text: 'Bomberos'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Description ───────────────────────────────────────────
                  Text(
                    'Apoyo al entrenamiento individual de aprendices e '
                    'instructores en el uso de EPP y reporte de desempeño.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary300,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // ── CTA Button with red shadow ─────────────────────────
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonShadow,
                          blurRadius: 28,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AppButton(
                      label: 'Comenzar →',
                      onPressed: () => context.push(RouteNames.login),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Version footer ────────────────────────────────────────
                  Text(
                    'Versión 1.0.0 © Bomberos TG',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary500,
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
