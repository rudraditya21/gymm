import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/pr_result.dart';
import '../../models/workout.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';
import '../history/workout_detail_screen.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  final Workout workout;
  final List<PRResult> prs;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.prs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final useKg = ref.watch(settingsProvider).useKg;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Title
              Text(
                'Workout done!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                workout.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 32),

              // Stats row
              Row(
                children: [
                  _StatBox(
                    label: 'Duration',
                    value: formatDuration(workout.duration),
                    cs: cs,
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: 'Volume',
                    value: formatVolume(workout.totalVolume, useKg: useKg),
                    cs: cs,
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: 'Sets',
                    value: '${workout.completedSetsCount}',
                    cs: cs,
                  ),
                ],
              ),

              // PRs
              if (prs.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'NEW PERSONAL RECORDS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 10),
                ...prs.map((pr) => _PRRow(pr: pr, useKg: useKg, cs: cs)),
              ],

              const Spacer(),

              // Actions
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          WorkoutDetailScreen(workoutId: workout.id),
                    ));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _StatBox(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
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
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PRRow extends StatelessWidget {
  final PRResult pr;
  final bool useKg;
  final ColorScheme cs;

  const _PRRow({required this.pr, required this.useKg, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pr.exerciseName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            '${formatWeightNum(pr.weight, useKg: useKg)} × ${pr.reps}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
