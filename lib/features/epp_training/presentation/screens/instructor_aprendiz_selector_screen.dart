import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../data/models/aprendiz.dart';
import '../providers/aprendiz_provider.dart';

/// Pantalla exclusiva del instructor: selecciona el aprendiz al que va a
/// entrenar antes de iniciar la sesión EPP.
///
/// Flujo:
///  1. Instructor abre la pantalla → se cargan los aprendices del API.
///  2. Selecciona un aprendiz (o continúa sin seleccionar).
///  3. Se navega a [RouteNames.cameraPermission].
class InstructorAprendizSelectorScreen extends ConsumerStatefulWidget {
  const InstructorAprendizSelectorScreen({super.key});

  @override
  ConsumerState<InstructorAprendizSelectorScreen> createState() =>
      _InstructorAprendizSelectorScreenState();
}

class _InstructorAprendizSelectorScreenState
    extends ConsumerState<InstructorAprendizSelectorScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Aprendiz> _filter(List<Aprendiz> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((a) {
      return a.name.toLowerCase().contains(q) ||
          (a.username?.toLowerCase().contains(q) ?? false) ||
          (a.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aprendicesAsync = ref.watch(aprendicesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark0 : AppColors.secondary50,
      appBar: AppAppBar(
        title: 'Seleccionar Aprendiz',
      ),
      body: Column(
        children: [
          // ── Descripción + Buscador ────────────────────────────────────────
          Container(
            width: double.infinity,
            color: isDark ? AppColors.dark1 : Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige el aprendiz para esta sesión de entrenamiento EPP.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white60
                        : AppColors.dark0.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.dark0,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o usuario…',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.dark0
                        : AppColors.secondary50,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Lista filtrada ────────────────────────────────────────────────
          Expanded(
            child: aprendicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(aprendicesProvider),
              ),
              data: (list) {
                final filtered = _filter(list);
                if (list.isEmpty) return const _EmptyView();
                if (filtered.isEmpty) return const _NoResultsView();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _AprendizTile(
                    aprendiz: filtered[i],
                    isDark: isDark,
                    onTap: () => _select(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _select(Aprendiz aprendiz) {
    ref.read(selectedAprendizProvider.notifier).select(aprendiz);
    context.push(RouteNames.cameraPermission);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de aprendiz
// ─────────────────────────────────────────────────────────────────────────────

class _AprendizTile extends StatelessWidget {
  const _AprendizTile({
    required this.aprendiz,
    required this.isDark,
    required this.onTap,
  });

  final Aprendiz aprendiz;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.dark1 : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar con iniciales
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary5.withValues(alpha: 0.15),
                backgroundImage: aprendiz.avatarUrl != null
                    ? NetworkImage(aprendiz.avatarUrl!)
                    : null,
                child: aprendiz.avatarUrl == null
                    ? Text(
                        aprendiz.initials,
                        style: TextStyle(
                          color: AppColors.primary5,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Nombre y usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aprendiz.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.dark0,
                      ),
                    ),
                    if (aprendiz.username != null || aprendiz.email != null)
                      Text(
                        aprendiz.username ?? aprendiz.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : AppColors.dark0.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vacío / error
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No hay aprendices registrados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Sin resultados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              'Error al cargar aprendices',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
