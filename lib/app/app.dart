import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_notifier.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

class BomberosApp extends ConsumerStatefulWidget {
  const BomberosApp({super.key});

  @override
  ConsumerState<BomberosApp> createState() => _BomberosAppState();
}

class _BomberosAppState extends ConsumerState<BomberosApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cuando la app pasa a primer plano, refrescamos los permisos del usuario
  /// desde /auth/me para reflejar cambios que pudo haber hecho el admin.
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      ref.read(authNotifierProvider.notifier).refreshMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    final themeMode = ref.watch(themeModeProvider);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Bomberos TG',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
