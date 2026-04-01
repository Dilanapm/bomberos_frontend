import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppToast {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, background: AppColors.success600);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, background: AppColors.primary7);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, background: AppColors.info600);
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color background,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
