import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/workout.dart';

class WorkoutCalendar extends StatelessWidget {
  final List<Workout> workouts;

  const WorkoutCalendar({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    // weekday: 1=Mon..7=Sun, offset so Mon=0
    final startOffset = (firstOfMonth.weekday - 1) % 7;

    // Build a set of active days (day numbers) and volume map
    final volumeByDay = <int, double>{};
    for (final w in workouts) {
      if (w.startedAt.year == now.year &&
          w.startedAt.month == now.month) {
        volumeByDay.update(
          w.startedAt.day,
          (v) => v + w.totalVolume,
          ifAbsent: () => w.totalVolume,
        );
      }
    }

    double maxVol =
        volumeByDay.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVol == 0) maxVol = 1;

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Text(
          _monthName(now.month),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
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
        // Calendar grid
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
            final vol = volumeByDay[day];
            final isToday = day == now.day;
            final intensity =
                vol != null ? (vol / maxVol).clamp(0.2, 1.0) : 0.0;

            return Container(
              decoration: BoxDecoration(
                color: vol != null
                    ? cs.primary.withValues(alpha: intensity * 0.85)
                    : cs.secondary,
                borderRadius: BorderRadius.circular(4),
                border: isToday
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w400,
                  color: vol != null
                      ? (intensity > 0.5
                          ? cs.onPrimary
                          : cs.onSurface)
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _monthName(int m) => const [
        '',
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ][m];
}
