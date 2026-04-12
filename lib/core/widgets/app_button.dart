import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'tap_scale.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bool disabled = isDisabled || isLoading || onPressed == null;

    final Color bg = switch (variant) {
      AppButtonVariant.primary => AppColors.primary5,
      AppButtonVariant.secondary => Colors.transparent,
      AppButtonVariant.danger => AppColors.primary7,
    };

    final Color fg = switch (variant) {
      AppButtonVariant.primary => AppColors.white,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.primary,
      AppButtonVariant.danger => AppColors.white,
    };

    final BorderSide border = switch (variant) {
      AppButtonVariant.secondary => BorderSide(color: AppColors.secondary200, width: 1),
      _ => BorderSide.none,
    };

    return TapScale(
      enabled: !disabled,
      child: SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border,
          ),
          disabledBackgroundColor: AppColors.secondary200,
          disabledForegroundColor: AppColors.secondary500,
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
