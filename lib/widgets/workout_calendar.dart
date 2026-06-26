import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/hive_service.dart';
import '../models/routine.dart';
import '../models/scheduled_entry.dart';
import '../models/workout.dart';
import '../providers/active_workout_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/schedule_provider.dart';
import '../screens/workout/active_workout_screen.dart';
import '../screens/workout/routine_editor_screen.dart';

class WorkoutCalendar extends ConsumerStatefulWidget {
  const WorkoutCalendar({super.key});

  @override
  ConsumerState<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends ConsumerState<WorkoutCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  bool get _canGoPrev {
    final ob = HiveService.onboardingDate;
    final prev = DateTime(_month.year, _month.month - 1, 1);
    return !prev.isBefore(DateTime(ob.year, ob.month, 1));
  }

  void _prev() {
    if (!_canGoPrev) return;
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  }

  void _next() => setState(
      () => _month = DateTime(_month.year, _month.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final schedule = ref.watch(scheduleProvider);
    final now = DateTime.now();

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset = (_month.weekday - 1) % 7;

    // Volume per day this month
    final volumeByDay = <int, double>{};
    final workoutByDay = <int, Workout>{};
    for (final w in history) {
      if (w.startedAt.year == _month.year &&
          w.startedAt.month == _month.month) {
        volumeByDay.update(
            w.startedAt.day, (v) => v + w.totalVolume,
            ifAbsent: () => w.totalVolume);
        workoutByDay[w.startedAt.day] = w;
      }
    }

    // Schedule per day this month
    final scheduleByDay = <int, ScheduledEntry>{};
    for (final e in schedule) {
      if (e.date.year == _month.year && e.date.month == _month.month) {
        scheduleByDay[e.date.day] = e;
      }
    }

    double maxVol =
        volumeByDay.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVol == 0) maxVol = 1;

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation
        Row(
          children: [
            _NavBtn(icon: Icons.chevron_left, onTap: _canGoPrev ? _prev : null, cs: cs),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            _NavBtn(icon: Icons.chevron_right, onTap: _next, cs: cs),
          ],
        ),
        const SizedBox(height: 6),

        // Day-of-week headers
        Row(
          children: dayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox();
            final day = i - startOffset + 1;
            final date = DateTime(_month.year, _month.month, day);
            final ob = HiveService.onboardingDate;
            // Compare components directly — avoids any local-midnight/UTC ambiguity.
            final isBeforeObMonth = _month.year < ob.year ||
                (_month.year == ob.year && _month.month < ob.month);
            final isInObMonth =
                _month.year == ob.year && _month.month == ob.month;
            final isBlocked =
                isBeforeObMonth || (isInObMonth && day < ob.day);
            final vol = volumeByDay[day];
            final sched = scheduleByDay[day];
            final isToday = day == now.day &&
                _month.month == now.month &&
                _month.year == now.year;
            final intensity =
                vol != null ? (vol / maxVol).clamp(0.2, 1.0) : 0.0;

            final hasWorkout = vol != null;
            final isRest = sched?.isRestDay == true;
            final isScheduled = sched != null && !sched.isRestDay;

            // Blocked cells (before onboarding date) — dim, no interaction.
            if (isBlocked) {
              return Container(
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.15),
                  ),
                ),
              );
            }

            Color bg;
            Border? border;
            if (hasWorkout) {
              bg = cs.primary.withValues(alpha: intensity * 0.85);
            } else if (isRest) {
              bg = cs.error.withValues(alpha: 0.10);
            } else {
              bg = cs.secondary;
            }

            if (isToday) {
              border = Border.all(color: cs.primary, width: 1.5);
            } else if (isScheduled && !hasWorkout) {
              border = Border.all(
                  color: cs.primary.withValues(alpha: 0.6), width: 1.5);
            } else if (isRest) {
              border = Border.all(
                  color: cs.error.withValues(alpha: 0.35), width: 1);
            }

            return GestureDetector(
              onTap: () => _onDayTap(
                context,
                date: date,
                workout: workoutByDay[day],
                scheduled: sched,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                  border: border,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: hasWorkout
                            ? (intensity > 0.5
                                ? cs.onPrimary
                                : cs.onSurface)
                            : isRest
                                ? cs.error.withValues(alpha: 0.7)
                                : cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    if (isScheduled && !hasWorkout)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (isRest)
                      Text(
                        'zzz',
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                          color: cs.error.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Legend
        const SizedBox(height: 10),
        Row(
          children: [
            _LegendDot(color: cs.primary, label: 'Workout', cs: cs),
            const SizedBox(width: 14),
            _LegendDot(
                color: Colors.transparent,
                border: cs.primary.withValues(alpha: 0.6),
                label: 'Scheduled',
                cs: cs),
            const SizedBox(width: 14),
            _LegendDot(
                color: cs.error.withValues(alpha: 0.10),
                border: cs.error.withValues(alpha: 0.35),
                label: 'zzz',
                cs: cs),
          ],
        ),
      ],
    );
  }

  void _onDayTap(
    BuildContext context, {
    required DateTime date,
    required Workout? workout,
    required ScheduledEntry? scheduled,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _DaySheet(
        date: date,
        workout: workout,
        scheduled: scheduled,
      ),
    );
  }

  static String _monthName(int m) => const [
        '',
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ][m];
}

// ── Nav button ────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _NavBtn({required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(icon,
            size: 20,
            color: cs.onSurface.withValues(alpha: onTap != null ? 0.55 : 0.2)),
      ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? border;
  final String label;
  final ColorScheme cs;
  const _LegendDot(
      {required this.color,
      this.border,
      required this.label,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                border != null ? Border.all(color: border!, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

// ── Day bottom sheet ──────────────────────────────────────────────────────────

class _DaySheet extends ConsumerWidget {
  final DateTime date;
  final Workout? workout;
  final ScheduledEntry? scheduled;

  const _DaySheet({
    required this.date,
    required this.workout,
    required this.scheduled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final routines = ref.watch(routinesProvider);

    final dateStr =
        '${_weekdayName(date.weekday)}, ${_monthShort(date.month)} ${date.day}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + date
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
            const SizedBox(height: 16),
            Text(
              dateStr,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Completed workout row
            if (workout != null) ...[
              _SheetRow(
                icon: Icons.check_circle_outline,
                iconColor: cs.primary,
                title: workout!.name,
                subtitle:
                    '${workout!.exercises.length} exercises · ${workout!.duration.inMinutes}m',
                cs: cs,
              ),
              const SizedBox(height: 12),
            ],

            // Scheduled row
            if (scheduled != null && !scheduled!.isRestDay) ...[
              _SheetRow(
                icon: Icons.event_outlined,
                iconColor: cs.primary,
                title: scheduled!.routineName ?? 'Scheduled workout',
                subtitle: 'Tap to start',
                cs: cs,
                onTap: () {
                  final r = ref
                      .read(routinesProvider)
                      .where((r) => r.id == scheduled!.routineId)
                      .firstOrNull;
                  if (r == null) return;
                  Navigator.of(context).pop();
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startFromRoutine(r);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ActiveWorkoutScreen(),
                  ));
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  ref.read(scheduleProvider.notifier).remove(date);
                  Navigator.of(context).pop();
                },
                child: Text('Remove schedule',
                    style: TextStyle(color: cs.error, fontSize: 13)),
              ),
              const SizedBox(height: 4),
            ],

            // Rest day row
            if (scheduled?.isRestDay == true) ...[
              _SheetRow(
                icon: Icons.bedtime_outlined,
                iconColor: cs.onSurface.withValues(alpha: 0.5),
                title: 'Rest day',
                subtitle: 'Recovery scheduled',
                cs: cs,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  ref.read(scheduleProvider.notifier).remove(date);
                  Navigator.of(context).pop();
                },
                child: Text('Remove',
                    style: TextStyle(color: cs.error, fontSize: 13)),
              ),
              const SizedBox(height: 4),
            ],

            // Action buttons when nothing scheduled
            if (scheduled == null) ...[
              // Schedule from routine
              if (routines.isNotEmpty) ...[
                Text(
                  'SCHEDULE FROM ROUTINE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                ...routines.map((r) => _RoutineOption(
                      routine: r,
                      cs: cs,
                      onTap: () {
                        ref
                            .read(scheduleProvider.notifier)
                            .scheduleRoutine(date, r.id, r.name);
                        Navigator.of(context).pop();
                      },
                    )),
                const SizedBox(height: 8),
              ],

              // Create routine
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RoutineEditorScreen(),
                  ));
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  routines.isEmpty
                      ? 'Create Routine to Schedule'
                      : 'Create New Routine',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.outline),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              // Rest day
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(scheduleProvider.notifier).markRestDay(date);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.bedtime_outlined, size: 16),
                  label: Text(
                    'Mark as Rest Day',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outline),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _weekdayName(int w) => const [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][w];

  static String _monthShort(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

// ── Sheet row ─────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _SheetRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.play_arrow_rounded,
                  color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Routine option ────────────────────────────────────────────────────────────

class _RoutineOption extends StatelessWidget {
  final Routine routine;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _RoutineOption(
      {required this.routine, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.secondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      '${routine.exercises.length} exercises',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_today_outlined,
                  color: cs.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
