import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_settings_provider.dart';
import 'providers/stabilization_provider.dart';
import 'providers/sensor_provider.dart';
import 'models/app_enums.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/stats/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Provider 초기화
  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.initialize();
  
  runApp(CalmRideApp(appSettingsProvider: appSettingsProvider));
}

class CalmRideApp extends StatelessWidget {
  final AppSettingsProvider appSettingsProvider;

  const CalmRideApp({
    super.key,
    required this.appSettingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettingsProvider),
        ChangeNotifierProvider(create: (_) => StabilizationProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp.router(
            title: 'CalmRide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(settingsProvider.settings.themeMode),
            routerConfig: _router,
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

// 라우터 설정
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (context, state) => const StatsScreen(),
        ),
      ],
    ),
  ],
);

/// 메인 네비게이션 셸
class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '설정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: '통계',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/settings')) {
      return 1;
    }
    if (location.startsWith('/stats')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/settings');
        break;
      case 2:
        GoRouter.of(context).go('/stats');
        break;
    }
  }
}
