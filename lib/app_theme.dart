import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/hive_service.dart';

const _themeModeKey = 'themeMode';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void restoreThemeMode() {
  final savedMode = HiveService.settings.get(_themeModeKey) as String?;
  themeNotifier.value = ThemeMode.values
      .where((mode) => mode.name == savedMode)
      .firstOrNull ?? ThemeMode.system;
}

Future<void> setThemeMode(ThemeMode mode) async {
  await HiveService.settings.put(_themeModeKey, mode.name);
  themeNotifier.value = mode;
}

TextTheme dmSansTextTheme([TextTheme? base]) {
  final textTheme = GoogleFonts.dmSansTextTheme(base);
  TextStyle? regular(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w400);

  return textTheme.copyWith(
    displayLarge: regular(textTheme.displayLarge),
    displayMedium: regular(textTheme.displayMedium),
    displaySmall: regular(textTheme.displaySmall),
    headlineLarge: regular(textTheme.headlineLarge),
    headlineMedium: regular(textTheme.headlineMedium),
    headlineSmall: regular(textTheme.headlineSmall),
    titleLarge: regular(textTheme.titleLarge),
    titleMedium: regular(textTheme.titleMedium),
    titleSmall: regular(textTheme.titleSmall),
    bodyLarge: regular(textTheme.bodyLarge),
    bodyMedium: regular(textTheme.bodyMedium),
    bodySmall: regular(textTheme.bodySmall),
    labelLarge: regular(textTheme.labelLarge),
    labelMedium: regular(textTheme.labelMedium),
    labelSmall: regular(textTheme.labelSmall),
  );
}
