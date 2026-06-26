String formatWeight(double? weight, {required bool useKg}) {
  if (weight == null) return '-';
  final unit = useKg ? 'kg' : 'lb';
  final value = useKg ? weight : weight * 2.20462;
  if (value == value.truncateToDouble()) {
    return '${value.toInt()} $unit';
  }
  return '${value.toStringAsFixed(1)} $unit';
}

String formatWeightNum(double? weight, {required bool useKg}) {
  if (weight == null) return '';
  final value = useKg ? weight : weight * 2.20462;
  if (value == value.truncateToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(1);
}

double toKg(double value, {required bool useKg}) {
  return useKg ? value : value / 2.20462;
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

String formatDurationCompact(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatVolume(double volume, {required bool useKg}) {
  final value = useKg ? volume : volume * 2.20462;
  final unit = useKg ? 'kg' : 'lb';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k $unit';
  return '${value.toInt()} $unit';
}

double estimate1RM(double weight, int reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return weight;
  if (reps > 36) return weight;
  // Brzycki formula
  return weight * (36 / (37 - reps));
}
