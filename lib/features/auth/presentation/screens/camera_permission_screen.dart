import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';

class CameraPermissionScreen extends StatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  State<CameraPermissionScreen> createState() =>
      _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends State<CameraPermissionScreen> {
  bool _loading = false;

  Future<void> _requestPermission() async {
    setState(() => _loading = true);

    final status = await Permission.camera.request();

    if (!mounted) return;
    setState(() => _loading = false);

    if (status.isGranted) {
      context.push(RouteNames.eppTraining);
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog();
    } else {
      // Denegado pero se puede volver a pedir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Permiso de cámara requerido para continuar.'),
          backgroundColor: AppColors.primary5,
        ),
      );
    }
  }

  void _showPermanentlyDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso bloqueado'),
        content: const Text(
          'El acceso a la cámara está bloqueado. '
          'Ve a Configuración > Aplicaciones > Bomberos I '
          'y activa el permiso de cámara.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final bgColor   = isDark ? AppColors.dark0 : AppColors.secondary50;
    final titleColor = isDark ? AppColors.secondary50  : AppColors.secondary800;
    final bodyColor  = isDark ? AppColors.secondary300 : AppColors.secondary600;
    final footerColor = isDark ? AppColors.secondary500 : AppColors.secondary400;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppAppBar(
        backgroundColor: bgColor,
        showDivider: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.secondary50 : AppColors.secondary700,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Ícono con círculos concéntricos ──────────────────
                  _CameraIconStack(isDark: isDark),

                  const SizedBox(height: 32),

                  // ── Título ─────────────────────────────────────────────
                  Text(
                    'Acceso a la cámara\nnecesario',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

              // ── Descripción ─────────────────────────────────────────────
              Text(
                'El sistema utilizará la cámara para analizar '
                'la colocación de tu EPP en tiempo real y '
                'validar tu seguridad.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: bodyColor,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              // ── Preview placeholder ─────────────────────────────────────
              _ScanPreview(isDark: isDark),

              const Spacer(),

              const SizedBox(height: 24),

              // ── Botón permitir acceso ─────────────────────────────────
              AppButton(
                label: 'Permitir acceso  →',
                isLoading: _loading,
                onPressed: _loading ? null : _requestPermission,
              ),

              const SizedBox(height: 16),

              // ── Más información ─────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  // TODO: mostrar bottom sheet con detalles de privacidad
                },
                child: Text(
                  'Más información',
                  style: textTheme.labelMedium?.copyWith(
                    color: isDark ? AppColors.secondary300 : AppColors.secondary600,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        isDark ? AppColors.secondary300 : AppColors.secondary600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Footer ──────────────────────────────────────────────────
              Text(
                'Puedes cambiar esto más tarde en la configuración\nde tu dispositivo.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: footerColor,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ícono con aros concéntricos
// ─────────────────────────────────────────────────────────────────────────────

class _CameraIconStack extends StatelessWidget {
  const _CameraIconStack({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aro exterior
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primary5.withAlpha(20)
                  : AppColors.primary5.withAlpha(18),
            ),
          ),
          // Aro medio
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primary5.withAlpha(35)
                  : AppColors.primary5.withAlpha(30),
            ),
          ),
          // Círculo central con ícono
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary5,
            ),
            child: const Icon(
              AppIcons.camera,
              size: 40,
              color: AppColors.white,
            ),
          ),
          // Badge escudo (inferior derecho)
          Positioned(
            bottom: 22,
            right: 22,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
              ),
              child: const Icon(
                AppIcons.shield,
                size: 18,
                color: AppColors.primary5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview placeholder de escaneo
// ─────────────────────────────────────────────────────────────────────────────

class _ScanPreview extends StatelessWidget {
  const _ScanPreview({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.dark3 : AppColors.secondary200,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Marco de escaneo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary5, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              AppIcons.camera,
              size: 24,
              color: AppColors.primary5,
            ),
          ),

          // Etiqueta inferior
          Positioned(
            bottom: 14,
            child: Text(
              'ESCANEANDO EPP',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.primary5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
