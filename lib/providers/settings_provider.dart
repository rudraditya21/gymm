import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final box = HiveService.settings;
    return AppSettings(
      useKg: box.get('useKg', defaultValue: true) as bool,
      restSeconds: box.get('restSeconds', defaultValue: 90) as int,
    );
  }

  void setUseKg(bool value) {
    HiveService.settings.put('useKg', value);
    state = state.copyWith(useKg: value);
  }

  void setRestSeconds(int value) {
    HiveService.settings.put('restSeconds', value);
    state = state.copyWith(restSeconds: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
