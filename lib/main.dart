import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'constants/colors.dart';
import 'data/hive_service.dart';
import 'screens/exercises/exercises_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const ProviderScope(child: GymmApp()));
}

class GymmApp extends StatelessWidget {
  const GymmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Gymm',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppLightColors.background,
          colorScheme: const ColorScheme.light(
            primary: AppLightColors.primary,
            onPrimary: AppLightColors.primaryForeground,
            secondary: AppLightColors.secondary,
            onSecondary: AppLightColors.secondaryForeground,
            surface: AppLightColors.card,
            onSurface: AppLightColors.foreground,
            error: AppLightColors.destructive,
            outline: AppLightColors.border,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppDarkColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppDarkColors.primary,
            onPrimary: AppDarkColors.primaryForeground,
            secondary: AppDarkColors.secondary,
            onSecondary: AppDarkColors.secondaryForeground,
            surface: AppDarkColors.card,
            onSurface: AppDarkColors.foreground,
            error: AppDarkColors.destructive,
            outline: AppDarkColors.border,
          ),
        ),
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    ExercisesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outline, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          indicatorColor: cs.primary.withValues(alpha: 0.08),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: cs.onSurface.withValues(alpha: 0.45)),
              selectedIcon: Icon(Icons.home_rounded, color: cs.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined,
                  color: cs.onSurface.withValues(alpha: 0.45)),
              selectedIcon:
                  Icon(Icons.calendar_month, color: cs.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined,
                  color: cs.onSurface.withValues(alpha: 0.45)),
              selectedIcon:
                  Icon(Icons.fitness_center, color: cs.primary),
              label: 'Exercises',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: cs.onSurface.withValues(alpha: 0.45)),
              selectedIcon: Icon(Icons.person, color: cs.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
