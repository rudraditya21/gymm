import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import 'exercise_picker_screen.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine? existing;

  const RoutineEditorScreen({super.key, this.existing});

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late TextEditingController _nameCtrl;
  late List<_EditableExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.existing?.name ?? '',
    );
    _exercises = (widget.existing?.exercises ?? [])
        .map((re) => _EditableExercise(
              exerciseId: re.exerciseId,
              exerciseName: re.exerciseName,
              sets: re.sets
                  .map((s) => _EditableSet(
                        weightCtrl: TextEditingController(
                          text: s.weightTarget?.toString() ?? '',
                        ),
                        repsCtrl: TextEditingController(
                          text: s.repsTarget?.toString() ?? '',
                        ),
                      ))
                  .toList(),
            ))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.weightCtrl.dispose();
        s.repsCtrl.dispose();
      }
    }
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _exercises.add(_EditableExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        sets: [
          _EditableSet(
            weightCtrl: TextEditingController(),
            repsCtrl: TextEditingController(),
          ),
        ],
      ));
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a routine name')),
      );
      return;
    }

    final routineExercises = _exercises.map((ex) {
      final sets = ex.sets.map((s) {
        final w = double.tryParse(s.weightCtrl.text.trim());
        final r = int.tryParse(s.repsCtrl.text.trim());
        return RoutineSet(weightTarget: w, repsTarget: r);
      }).toList();
      return RoutineExercise(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        sets: sets,
      );
    }).toList();

    final notifier = ref.read(routinesProvider.notifier);
    if (widget.existing != null) {
      await notifier.save(Routine(
        id: widget.existing!.id,
        name: name,
        createdAt: widget.existing!.createdAt,
        exercises: routineExercises,
      ));
    } else {
      await notifier.create(name: name, exercises: routineExercises);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.existing == null ? 'New Routine' : 'Edit Routine',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Routine name',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
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
          const SizedBox(height: 24),
          ..._exercises.asMap().entries.map((entry) {
            final ei = entry.key;
            final ex = entry.value;
            return _RoutineExerciseCard(
              exercise: ex,
              cs: cs,
              onRemove: () => setState(() => _exercises.removeAt(ei)),
              onAddSet: () => setState(() => ex.sets.add(_EditableSet(
                    weightCtrl: TextEditingController(),
                    repsCtrl: TextEditingController(),
                  ))),
              onRemoveSet: (si) => setState(() => ex.sets.removeAt(si)),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExercisePickerScreen(onSelect: _addExercise),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              'Add Exercise',
              style: GoogleFonts.dmSans(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.outline),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableSet {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  _EditableSet({required this.weightCtrl, required this.repsCtrl});
}

class _EditableExercise {
  final String exerciseId;
  final String exerciseName;
  final List<_EditableSet> sets;

  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class _RoutineExerciseCard extends StatelessWidget {
  final _EditableExercise exercise;
  final ColorScheme cs;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final void Function(int) onRemoveSet;

  const _RoutineExerciseCard({
    required this.exercise,
    required this.cs,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((e) {
            final si = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Row(
                children: [
                  Text('${si + 1}',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.45))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallField(
                        ctrl: s.weightCtrl, hint: 'weight', cs: cs),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        _SmallField(ctrl: s.repsCtrl, hint: 'reps', cs: cs),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    onPressed: () => onRemoveSet(si),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: onAddSet,
            icon: Icon(Icons.add, size: 14, color: cs.primary),
            label: Text('Add Set',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.primary)),
          ),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final ColorScheme cs;
  const _SmallField(
      {required this.ctrl, required this.hint, required this.cs});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          TextInputType.numberWithOptions(decimal: hint == 'weight'),
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(fontSize: 13, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: cs.secondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
