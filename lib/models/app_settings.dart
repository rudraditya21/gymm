class AppSettings {
  final bool useKg;
  final bool useCm;
  final int restSeconds;
  final bool autoStartRest;

  const AppSettings({
    this.useKg = true,
    this.useCm = true,
    this.restSeconds = 90,
    this.autoStartRest = true,
  });

  AppSettings copyWith({
    bool? useKg,
    bool? useCm,
    int? restSeconds,
    bool? autoStartRest,
  }) =>
      AppSettings(
        useKg: useKg ?? this.useKg,
        useCm: useCm ?? this.useCm,
        restSeconds: restSeconds ?? this.restSeconds,
        autoStartRest: autoStartRest ?? this.autoStartRest,
      );
}
