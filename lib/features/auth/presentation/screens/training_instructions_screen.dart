import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de ítem de instrucción
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionItem {
  const _InstructionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _kItems = [
  _InstructionItem(
    icon:     AppIcons.lightbulb,
    title:    'Iluminación adecuada',
    subtitle: 'Evita sombras fuertes',
  ),
  _InstructionItem(
    icon:     AppIcons.ruler,
    title:    'Distancia (2 metros)',
    subtitle: 'Espacio libre alrededor',
  ),
  _InstructionItem(
    icon:     AppIcons.pose,
    title:    'Vista casi frontal',
    subtitle: 'Cámara a la altura del pecho, da un paso hacia la '
        'izquierda para que tengas la vista casi frontal',
  ),
  _InstructionItem(
    icon:     AppIcons.shield,
    title:    'EPP Completo',
    subtitle: 'Casco, botas y guantes',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────────────────────

class TrainingInstructionsScreen extends StatefulWidget {
  const TrainingInstructionsScreen({super.key});

  @override
  State<TrainingInstructionsScreen> createState() =>
      _TrainingInstructionsScreenState();
}

class _TrainingInstructionsScreenState
    extends State<TrainingInstructionsScreen> {
  final List<bool> _checked = List.filled(_kItems.length, false);

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final textTheme  = Theme.of(context).textTheme;
    final bgColor    = isDark ? AppColors.dark0    : AppColors.secondary50;
    final titleColor = isDark ? AppColors.secondary50  : AppColors.secondary800;
    final bodyColor  = isDark ? AppColors.secondary200 : AppColors.secondary600;

    return Scaffold(
      backgroundColor: bgColor,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppAppBar(
        title: 'Instrucciones',
        centerTitle: true,
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal
                  Text(
                    'Preparación para el entrenamiento',
                    style: textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtítulo
                  Text(
                    'Verifica las siguientes condiciones de seguridad y '
                    'entorno antes de iniciar.',
                    style: textTheme.bodySmall?.copyWith(
                      color: bodyColor,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Lista de ítems
                  ...List.generate(_kItems.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CheckItem(
                        isDark:  isDark,
                        item:    _kItems[i],
                        checked: _checked[i],
                        onToggle: () =>
                            setState(() => _checked[i] = !_checked[i]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Botón Continuar ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24,
              MediaQuery.paddingOf(context).bottom + 20,
            ),
            child: AppButton(
              label:     'CONTINUAR →',
              onPressed: () => context.push(RouteNames.cameraPermission),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ítem con checkbox
// ─────────────────────────────────────────────────────────────────────────────

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.isDark,
    required this.item,
    required this.checked,
    required this.onToggle,
  });

  final bool isDark;
  final _InstructionItem item;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme    = Theme.of(context).textTheme;
    final cardColor    = isDark ? AppColors.cardDark   : AppColors.white;
    final borderColor  = isDark ? AppColors.dark3      : AppColors.secondary100;
    final titleColor   = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final subColor     = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final iconBg       = isDark
        ? Colors.white.withAlpha(18)
        : AppColors.primary5.withAlpha(20);
    final iconColor    = isDark ? AppColors.primary3 : AppColors.primary5;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ícono ──────────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 20, color: iconColor),
              ),

              const SizedBox(width: 14),

              // ── Texto ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.labelLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: subColor,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Checkbox ───────────────────────────────────────────────
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked
                        ? AppColors.primary5
                        : isDark
                            ? AppColors.dark4
                            : AppColors.secondary200,
                    width: 1.5,
                  ),
                  color: checked ? AppColors.primary5 : Colors.transparent,
                ),
                child: checked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
