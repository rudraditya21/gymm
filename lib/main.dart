import 'package:flutter/material.dart';

import 'constants/colors.dart';

void main() {
  runApp(const GymmApp());
}

class GymmApp extends StatelessWidget {
  const GymmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gymm',
      debugShowCheckedModeBanner: false,
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
          onError: AppLightColors.destructiveForeground,
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
          onError: AppDarkColors.destructiveForeground,
          outline: AppDarkColors.border,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
