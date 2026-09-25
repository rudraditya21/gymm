import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final box = HiveService.settings;
    return AppSettings(
      useKg: box.get('useKg', defaultValue: true) as bool,
      useCm: box.get('useCm', defaultValue: true) as bool,
      restSeconds: box.get('restSeconds', defaultValue: 90) as int,
      autoStartRest: box.get('autoStartRest', defaultValue: true) as bool,
    );
  }

  Future<void> setUseKg(bool value) async {
    await HiveService.settings.put('useKg', value);
    state = state.copyWith(useKg: value);
  }

  Future<void> setUseCm(bool value) async {
    await HiveService.settings.put('useCm', value);
    state = state.copyWith(useCm: value);
  }

  Future<void> setRestSeconds(int value) async {
    await HiveService.settings.put('restSeconds', value);
    state = state.copyWith(restSeconds: value);
  }

  Future<void> setAutoStartRest(bool value) async {
    await HiveService.settings.put('autoStartRest', value);
    state = state.copyWith(autoStartRest: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
