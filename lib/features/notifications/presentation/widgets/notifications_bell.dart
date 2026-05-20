import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../providers/unread_count_notifier.dart';

/// Botón de campana con badge de no leídas. Navega a la pantalla de
/// notificaciones al tocarlo. Auto-adaptativo a tema claro/oscuro.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadCountProvider);

    final iconColor =
        isDark ? AppColors.secondary50 : AppColors.secondary700;
    final bg = isDark ? AppColors.dark3 : AppColors.secondary100;
    final border = isDark ? AppColors.dark4 : AppColors.secondary200;

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bg,
        shape: CircleBorder(side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(RouteNames.notifications),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(AppIcons.notificationsOutlined,
                  color: iconColor, size: 22),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.dark0
                            : AppColors.secondary50,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
