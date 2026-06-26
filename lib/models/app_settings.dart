class AppSettings {
  final bool useKg;
  final int restSeconds;

  const AppSettings({this.useKg = true, this.restSeconds = 90});

  AppSettings copyWith({bool? useKg, int? restSeconds}) => AppSettings(
        useKg: useKg ?? this.useKg,
        restSeconds: restSeconds ?? this.restSeconds,
      );
}
