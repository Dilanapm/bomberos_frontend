import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icons.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_notifier.dart';
import '../providers/unread_count_notifier.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationsProvider.notifier).markAllAsRead();
    ref.read(unreadCountProvider.notifier).clear();
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.read) {
      await ref.read(notificationsProvider.notifier).markAsRead(n.id);
      ref.read(unreadCountProvider.notifier).decrement();
    }
    if (!mounted) return;
    final id = n.evaluationId;
    if (id == null) return;
    context.push(
      RouteNames.aprendizEvalDetail,
      extra: {'evalId': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state  = ref.watch(notificationsProvider);

    final bg = isDark ? AppColors.dark0 : AppColors.secondary50;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppAppBar(
        title: 'Notificaciones',
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(
          onRetry: () =>
              ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.isEmpty) return const _EmptyView();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.items.length + (data.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                if (i >= data.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final n = data.items[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _onTap(n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tile
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final titleColor = isDark ? AppColors.secondary50  : AppColors.secondary700;
    final subColor   = isDark ? AppColors.secondary400 : AppColors.secondary500;
    final dotColor   = AppColors.primary5;

    final (icon, accent) = switch (notification.kind) {
      NotificationKind.evaluacionGuardada  =>
        (Icons.assignment_turned_in_rounded, AppColors.success600),
      NotificationKind.evaluacionRevisada  =>
        (Icons.rate_review_rounded, AppColors.info500),
      NotificationKind.unknown =>
        (AppIcons.notificationsOutlined, AppColors.secondary400),
    };

    final iconBg = isDark
        ? Colors.white.withAlpha(18)
        : accent.withAlpha(28);

    return TapScale(
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(notification),
                      style: textTheme.labelLarge?.copyWith(
                        color: titleColor,
                        fontWeight:
                            notification.read ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message ?? '',
                      style: textTheme.bodySmall?.copyWith(
                        color: subColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRelative(notification.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: subColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AppNotification n) {
    switch (n.kind) {
      case NotificationKind.evaluacionGuardada:
        return 'Nueva evaluación guardada';
      case NotificationKind.evaluacionRevisada:
        final ins = n.data['instructor_name'] as String?;
        return ins != null
            ? 'Revisión del instructor $ins'
            : 'Tu evaluación fue revisada';
      case NotificationKind.unknown:
        return 'Notificación';
    }
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7)     return 'Hace ${diff.inDays} d';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty / Error
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = Theme.of(context).textTheme;
    final subColor =
        isDark ? AppColors.secondary400 : AppColors.secondary500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.notificationsOutlined,
              size: 56,
              color: subColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: text.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.secondary50
                    : AppColors.secondary700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando tengas avisos, los verás aquí.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: subColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.secondary400,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tus notificaciones',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              onPressed: onRetry,
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
