import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/routine.dart';
import '../../providers/active_workout_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/workout/active_workout_screen.dart';
import '../../screens/workout/routine_editor_screen.dart';
import '../../utils/format.dart';
import '../../widgets/workout_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final routines = ref.watch(routinesProvider);
    final useKg = ref.watch(settingsProvider).useKg;

    // This week stats
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = history.where((w) => w.startedAt.isAfter(
          DateTime(weekStart.year, weekStart.month, weekStart.day),
        ));
    final weekCount = thisWeek.length;
    final weekVolume =
        thisWeek.fold<double>(0, (s, w) => s + w.totalVolume);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Gymm',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // This Week
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _WeekStat(
                    label: 'This week',
                    value: '$weekCount ${weekCount == 1 ? 'workout' : 'workouts'}',
                    cs: cs,
                  ),
                  if (weekVolume > 0) ...[
                    const SizedBox(width: 24),
                    _WeekStat(
                      label: 'Volume',
                      value: formatVolume(weekVolume, useKg: useKg),
                      cs: cs,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Start Workout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _showStartSheet(context, ref, routines),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Workout',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Routines section
            if (routines.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'ROUTINES',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RoutineEditorScreen(),
                        ),
                      ),
                      child: Text(
                        'New',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _RoutineCard(
                    routine: routines[i],
                    cs: cs,
                    onStart: () => _startFromRoutine(context, ref, routines[i]),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RoutineEditorScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Create Routine',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Recent workout
            if (history.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'RECENT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WorkoutCard(
                  workout: history.first,
                  useKg: useKg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStartSheet(
      BuildContext context, WidgetRef ref, List<Routine> routines) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _StartSheet(
        routines: routines,
        onStartEmpty: () {
          Navigator.of(ctx).pop();
          _startEmpty(context, ref);
        },
        onStartRoutine: (r) {
          Navigator.of(ctx).pop();
          _startFromRoutine(context, ref, r);
        },
      ),
    );
  }

  void _startEmpty(BuildContext context, WidgetRef ref) {
    ref.read(activeWorkoutProvider.notifier).startEmpty();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  void _startFromRoutine(
      BuildContext context, WidgetRef ref, Routine routine) {
    ref.read(activeWorkoutProvider.notifier).startFromRoutine(routine);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _WeekStat(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final ColorScheme cs;
  final VoidCallback onStart;

  const _RoutineCard(
      {required this.routine, required this.cs, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routine.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${routine.exercises.length} exercises',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.play_arrow_rounded,
                    size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  'Start',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartSheet extends StatelessWidget {
  final List<Routine> routines;
  final VoidCallback onStartEmpty;
  final void Function(Routine) onStartRoutine;

  const _StartSheet({
    required this.routines,
    required this.onStartEmpty,
    required this.onStartRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStartEmpty,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Empty Workout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (routines.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'START FROM ROUTINE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              ...routines.map((r) => ListTile(
                    onTap: () => onStartRoutine(r),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      r.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${r.exercises.length} exercises',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
