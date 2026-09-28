import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'constants/colors.dart';
import 'data/hive_service.dart';
import 'models/active_workout.dart';
import 'providers/active_workout_provider.dart';
import 'screens/exercises/exercises_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/workout/active_workout_screen.dart';
import 'services/workout_notification_service.dart';
import 'widgets/active_workout_popover.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await WorkoutNotificationService.initialize();
  restoreThemeMode();
  runApp(const ProviderScope(child: GymmApp()));
}

class GymmApp extends ConsumerStatefulWidget {
  const GymmApp({super.key});

  @override
  ConsumerState<GymmApp> createState() => _GymmAppState();
}

class _GymmAppState extends ConsumerState<GymmApp> with WidgetsBindingObserver {
  late final ProviderSubscription<ActiveWorkoutState?> _workoutSubscription;
  var _openingActiveWorkout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutSubscription = ref.listenManual(
      activeWorkoutProvider,
      (_, workout) => _syncWorkoutNotification(workout),
      fireImmediately: true,
    );
    WorkoutNotificationService.registerTapHandler(_openActiveWorkout);
  }

  @override
  void dispose() {
    _workoutSubscription.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(activeWorkoutProvider.notifier).flush());
    }
  }

  void _syncWorkoutNotification(ActiveWorkoutState? workout) => unawaited(
        workout == null
            ? WorkoutNotificationService.cancel()
            : WorkoutNotificationService.show(workout.name),
      );

  void _openActiveWorkout() {
    if (_openingActiveWorkout) return;
    _openingActiveWorkout = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(activeWorkoutProvider) == null) {
        _openingActiveWorkout = false;
        return;
      }
      final route = _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      );
      if (route == null) {
        _openingActiveWorkout = false;
        return;
      }
      unawaited(route.whenComplete(() => _openingActiveWorkout = false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Gymm',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: dmSansTextTheme(),
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
          textTheme: dmSansTextTheme(ThemeData.dark().textTheme),
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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _pages),
          if (activeWorkout != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: ActiveWorkoutPopover(
                workout: activeWorkout,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                ),
              ),
            ),
        ],
      ),
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
