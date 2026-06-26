import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/active_workout_provider.dart';
import '../../widgets/exercise_block.dart';
import '../../widgets/rest_timer_bar.dart';
import 'exercise_picker_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(activeWorkoutProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmDiscard(context, notifier),
        ),
        title: GestureDetector(
          onTap: () => _renameDialog(context, workout.name, notifier),
          child: Text(
            workout.name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _ElapsedTimer(startedAt: workout.startedAt),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: workout.exercises.isEmpty
                  ? null
                  : () => _finish(context, notifier),
              child: Text(
                'Finish',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: workout.exercises.isEmpty
                      ? cs.onSurface.withValues(alpha: 0.3)
                      : cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: workout.exercises.isEmpty
                ? _EmptyState(cs: cs)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ...workout.exercises.asMap().entries.map((e) =>
                          ExerciseBlock(
                            key: ValueKey(e.value.exerciseId + e.key.toString()),
                            exerciseIndex: e.key,
                            exercise: e.value,
                          )),
                    ],
                  ),
          ),
          const RestTimerBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExercisePickerScreen(
              onSelect: (ex) => notifier.addExercise(ex),
            ),
          ),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Exercise',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _finish(
      BuildContext context, ActiveWorkoutNotifier notifier) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _FinishDialog(),
    );
    if (confirmed != true) return;
    final workout = await notifier.finish();
    nav.pop(workout);
  }

  Future<void> _confirmDiscard(
      BuildContext context, ActiveWorkoutNotifier notifier) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.cancel();
      nav.pop();
    }
  }

  Future<void> _renameDialog(
      BuildContext context, String current, ActiveWorkoutNotifier notifier) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Workout'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Workout name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) notifier.rename(result);
  }
}

class _ElapsedTimer extends StatefulWidget {
  final DateTime startedAt;
  const _ElapsedTimer({required this.startedAt});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(widget.startedAt);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center,
              size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Exercise" to get started',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finish Workout?'),
      content:
          const Text('Save this workout to your history?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Finish'),
        ),
      ],
    );
  }
}
