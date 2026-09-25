import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/workout.dart';
import '../utils/format.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final bool useKg;
  final VoidCallback? onTap;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.useKg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = workout.startedAt;
    final dateStr =
        '${_monthName(date.month)} ${date.day}, ${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workout.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Stat(
                  icon: Icons.timer_outlined,
                  label: formatDuration(workout.duration),
                  cs: cs,
                ),
                const SizedBox(width: 16),
                _Stat(
                  icon: Icons.fitness_center,
                  label: formatVolume(workout.totalVolume, useKg: useKg),
                  cs: cs,
                ),
                const SizedBox(width: 16),
                _Stat(
                  icon: Icons.check_circle_outline,
                  label: '${workout.completedSetsCount} sets',
                  cs: cs,
                ),
              ],
            ),
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                workout.exercises.map((e) => e.exerciseName).join(' · '),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _Stat({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
