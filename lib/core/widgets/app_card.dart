import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Tarjeta contenedora con borde y fondo adaptativo light/dark.
///
/// Uso:
/// ```dart
/// AppCard(
///   child: Column(children: [...]),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;

  /// Padding interno opcional. Si es null, el hijo gestiona su propio padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dark3 : AppColors.secondary100,
          width: 1,
        ),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
