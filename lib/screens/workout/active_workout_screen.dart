import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/active_workout.dart';
import '../../providers/active_workout_provider.dart';
import '../../widgets/exercise_block.dart';
import '../../widgets/rest_timer_bar.dart';
import 'exercise_picker_screen.dart';
import 'workout_summary_screen.dart';

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
        // Workout name + elapsed timer stacked vertically
        title: GestureDetector(
          onTap: () => _renameDialog(context, workout.name, notifier),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workout.name,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              _ElapsedTimer(startedAt: workout.startedAt, cs: cs),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: workout.exercises.isEmpty
                  ? null
                  : () => _finish(context, notifier),
              child: Text(
                'Finish',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
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
          // Exercises list
          Expanded(
            child: workout.exercises.isEmpty
                ? _EmptyState(cs: cs)
                : ReorderableListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    onReorder: notifier.reorderExercises,
                    footer: _NotesField(
                      initial: workout.notes,
                      cs: cs,
                      onChanged: notifier.setNotes,
                    ),
                    children: _buildExerciseBlocks(workout.exercises),
                  ),
          ),
          // Add exercise — fixed above rest timer, never overlaps
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline)),
            ),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExercisePickerScreen(
                    onSelect: (ex) => notifier.addExercise(ex),
                  ),
                ),
              ),
              icon: Icon(Icons.add, size: 18, color: cs.primary),
              label: Text(
                'Add Exercise',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          // Rest timer — appears below the button, above safe area
          const RestTimerBar(),
        ],
      ),
    );
  }

  List<Widget> _buildExerciseBlocks(List<ActiveExercise> exercises) {
    // Map groupId → ordered list of indices in that group
    final groups = <String, List<int>>{};
    for (int i = 0; i < exercises.length; i++) {
      final gid = exercises[i].supersetGroupId;
      if (gid != null) groups.putIfAbsent(gid, () => []).add(i);
    }

    return exercises.asMap().entries.map((e) {
      final i = e.key;
      final ex = e.value;
      final gid = ex.supersetGroupId;

      String? label;
      bool isLast = true;

      if (gid != null) {
        final positions = groups[gid] ?? [];
        final pos = positions.indexOf(i);
        if (pos >= 0) {
          label = String.fromCharCode('A'.codeUnitAt(0) + pos);
          isLast = pos == positions.length - 1;
        }
      }

      return ExerciseBlock(
        key: ValueKey('${ex.exerciseId}_$i'),
        exerciseIndex: i,
        exercise: ex,
        supersetLabel: label,
        isLastInSuperset: isLast,
        isLastExercise: i == exercises.length - 1,
      );
    }).toList();
  }

  Future<void> _finish(
      BuildContext context, ActiveWorkoutNotifier notifier) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text('Save this workout to your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final (workout, prs) = await notifier.finish();
    nav.pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(workout: workout, prs: prs),
    ));
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

  Future<void> _renameDialog(BuildContext context, String current,
      ActiveWorkoutNotifier notifier) async {
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

// ── Notes Field ───────────────────────────────────────────────────────────────

class _NotesField extends StatefulWidget {
  final String initial;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  const _NotesField({
    required this.initial,
    required this.cs,
    required this.onChanged,
  });

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        maxLines: null,
        style: GoogleFonts.dmSans(fontSize: 14, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Workout notes…',
          hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.3)),
          filled: true,
          fillColor: cs.secondary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Elapsed Timer ─────────────────────────────────────────────────────────────

class _ElapsedTimer extends StatefulWidget {
  final DateTime startedAt;
  final ColorScheme cs;
  const _ElapsedTimer({required this.startedAt, required this.cs});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        color: widget.cs.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

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
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Exercise" below to get started',
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
