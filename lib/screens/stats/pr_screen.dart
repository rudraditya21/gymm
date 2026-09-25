import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';

class PRScreen extends ConsumerWidget {
  const PRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final useKg = ref.watch(settingsProvider).useKg;

    final prs = _computePRs(history);
    prs.sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Personal Records',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
      ),
      body: prs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'No records yet',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete a workout to see your PRs',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: prs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _PRCard(pr: prs[i], useKg: useKg, cs: cs),
            ),
    );
  }

  List<_PR> _computePRs(List history) {
    final map = <String, _PR>{};

    for (final workout in history) {
      for (final ex in workout.exercises) {
        for (final set in ex.sets) {
          if (!set.isWorkingSet || set.weight == null || set.reps == null) {
            continue;
          }
          final e1rm = estimate1RM(set.weight!, set.reps!);
          final existing = map[ex.exerciseId];
          if (existing == null || e1rm > existing.estimated1RM) {
            map[ex.exerciseId] = _PR(
              exerciseName: ex.exerciseName,
              weight: set.weight!,
              reps: set.reps!,
              estimated1RM: e1rm,
              date: workout.startedAt,
            );
          }
        }
      }
    }

    return map.values.toList();
  }
}

class _PR {
  final String exerciseName;
  final double weight;
  final int reps;
  final double estimated1RM;
  final DateTime date;

  const _PR({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.date,
  });
}

class _PRCard extends StatelessWidget {
  final _PR pr;
  final bool useKg;
  final ColorScheme cs;

  const _PRCard({required this.pr, required this.useKg, required this.cs});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_month(pr.date.month)} ${pr.date.day}, ${pr.date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatWeightNum(pr.weight, useKg: useKg)} ${useKg ? 'kg' : 'lb'} × ${pr.reps}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Est. 1RM ${formatWeight(pr.estimated1RM, useKg: useKg)}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _month(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}
