class AppSettings {
  final bool useKg;
  final bool useCm;
  final int restSeconds;

  const AppSettings({this.useKg = true, this.useCm = true, this.restSeconds = 90});

  AppSettings copyWith({bool? useKg, bool? useCm, int? restSeconds}) => AppSettings(
        useKg: useKg ?? this.useKg,
        useCm: useCm ?? this.useCm,
        restSeconds: restSeconds ?? this.restSeconds,
      );
}
