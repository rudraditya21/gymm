import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_theme.dart';
import '../../providers/body_weight_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/backup_restore.dart';
import '../../utils/csv_export.dart';
import '../../utils/format.dart';
import '../stats/muscle_heatmap_screen.dart';
import '../stats/pr_screen.dart';
import '../stats/volume_chart_screen.dart';
import '../tools/body_weight_screen.dart';
import '../tools/measurements_screen.dart';
import '../tools/plate_calculator_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _importing = false;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);

    final totalWorkouts = history.length;
    final totalVolume =
        history.fold<double>(0, (sum, w) => sum + w.totalVolume);
    final totalDuration = history.fold<Duration>(
        Duration.zero, (sum, w) => sum + w.duration);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Lifetime stats
            _SectionLabel('LIFETIME STATS'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _StatItem(
                      label: 'Workouts', value: '$totalWorkouts', cs: cs),
                  _StatItem(
                    label: 'Volume',
                    value: formatVolume(totalVolume, useKg: settings.useKg),
                    cs: cs,
                  ),
                  _StatItem(
                    label: 'Time',
                    value: _formatTotalTime(totalDuration),
                    cs: cs,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Appearance
            _SectionLabel('APPEARANCE'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ThemeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Units
            _SectionLabel('UNITS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Weight unit',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        _UnitToggle(
                          useKg: settings.useKg,
                          onChanged: (v) =>
                              ref.read(settingsProvider.notifier).setUseKg(v),
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Measurement unit',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        _MeasurementUnitToggle(
                          useCm: settings.useCm,
                          onChanged: (v) =>
                              ref.read(settingsProvider.notifier).setUseCm(v),
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rest timer
            _SectionLabel('REST TIMER'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Default rest',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        _RestPicker(
                          seconds: settings.restSeconds,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setRestSeconds(v),
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Auto-start timer',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: settings.autoStartRest,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setAutoStartRest(v),
                          activeColor: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stats
            _SectionLabel('STATS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MuscleHeatmapScreen())),
                    leading:
                        Icon(Icons.accessibility_new, color: cs.primary, size: 20),
                    title: Text('Muscle Activity',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Radar chart of recent sessions',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10))),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const VolumeChartScreen())),
                    leading: Icon(Icons.bar_chart_rounded,
                        color: cs.primary, size: 20),
                    title: Text('Volume Trend',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Weekly & monthly volume over time',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PRScreen())),
                    leading: Icon(Icons.emoji_events_outlined,
                        color: cs.primary, size: 20),
                    title: Text('Personal Records',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Best set per exercise, all time',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Tools
            _SectionLabel('TOOLS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PlateCalculatorScreen())),
                    leading:
                        Icon(Icons.fitness_center, color: cs.primary, size: 20),
                    title: Text('Plate Calculator',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('How many plates per side',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10))),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BodyWeightScreen())),
                    leading: Icon(Icons.monitor_weight_outlined,
                        color: cs.primary, size: 20),
                    title: Text('Body Weight',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Track weight over time',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MeasurementsScreen())),
                    leading: Icon(Icons.straighten_outlined,
                        color: cs.primary, size: 20),
                    title: Text('Body Measurements',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Waist, chest, biceps and more',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: () => exportWorkoutsAsCsv(),
                    leading: Icon(Icons.download_outlined,
                        color: cs.primary, size: 20),
                    title: Text('Export to CSV',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Share all workout history',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: _exporting ? null : _doExport,
                    leading: _exporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          )
                        : Icon(Icons.backup_outlined,
                            color: cs.primary, size: 20),
                    title: Text('Backup',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Export all data as JSON',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    onTap: _importing ? null : _doImport,
                    leading: _importing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          )
                        : Icon(Icons.restore_outlined,
                            color: cs.primary, size: 20),
                    title: Text('Restore',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    subtitle: Text('Import from a backup file',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      await exportBackup();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _doImport() async {
    setState(() => _importing = true);
    try {
      final result = await importBackup();
      if (result == null) return;

      // Refresh all providers so UI reflects imported data without restart
      ref.read(historyProvider.notifier).refresh();
      ref.read(routinesProvider.notifier).refresh();
      ref.read(exercisesProvider.notifier).refresh();
      ref.read(bodyWeightProvider.notifier).refresh();
      ref.read(measurementProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _formatTotalTime(Duration d) {
    final h = d.inHours;
    if (h == 0) return '${d.inMinutes}m';
    return '${h}h';
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: cs.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _StatItem(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, current, __) {
        return Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: cs.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: [
              _ThemeOption(
                  label: 'Light', mode: ThemeMode.light, current: current),
              _ThemeOption(
                  label: 'Dark', mode: ThemeMode.dark, current: current),
              _ThemeOption(
                  label: 'System', mode: ThemeMode.system, current: current),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final ThemeMode current;

  const _ThemeOption({
    required this.label,
    required this.mode,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = mode == current;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => themeNotifier.value = mode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.55),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _MeasurementUnitToggle extends StatelessWidget {
  final bool useCm;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;

  const _MeasurementUnitToggle(
      {required this.useCm, required this.onChanged, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitOption(
              label: 'cm',
              selected: useCm,
              onTap: () => onChanged(true),
              cs: cs),
          _UnitOption(
              label: 'in',
              selected: !useCm,
              onTap: () => onChanged(false),
              cs: cs),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final bool useKg;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;

  const _UnitToggle(
      {required this.useKg, required this.onChanged, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitOption(
              label: 'kg',
              selected: useKg,
              onTap: () => onChanged(true),
              cs: cs),
          _UnitOption(
              label: 'lb',
              selected: !useKg,
              onTap: () => onChanged(false),
              cs: cs),
        ],
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _UnitOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color:
                selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _RestPicker extends StatelessWidget {
  final int seconds;
  final ValueChanged<int> onChanged;
  final ColorScheme cs;

  const _RestPicker(
      {required this.seconds, required this.onChanged, required this.cs});

  static const _options = [30, 60, 90, 120, 180, 240, 300];

  @override
  Widget build(BuildContext context) {
    final label =
        seconds >= 60 ? '${seconds ~/ 60}m' : '${seconds}s';
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Rest Timer Default'),
            children: _options
                .map((s) => SimpleDialogOption(
                      onPressed: () => Navigator.of(ctx).pop(s),
                      child: Text(s >= 60
                          ? '${s ~/ 60} min${s % 60 != 0 ? ' ${s % 60}s' : ''}'
                          : '${s}s'),
                    ))
                .toList(),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
