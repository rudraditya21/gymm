import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/workout_card.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final useKg = ref.watch(settingsProvider).useKg;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: history.isEmpty
            ? _EmptyHistory(cs: cs)
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Text(
                        'History',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final workout = history[i];
                        return Dismissible(
                          key: ValueKey(workout.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Workout?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text('Delete',
                                      style: TextStyle(color: cs.error)),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) =>
                              ref.read(historyProvider.notifier).delete(workout.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: cs.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.delete_outline,
                                color: cs.error, size: 22),
                          ),
                          child: WorkoutCard(
                            workout: workout,
                            useKg: useKg,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutDetailScreen(workoutId: workout.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyHistory({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month,
              size: 56, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Finish your first workout to see it here',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
