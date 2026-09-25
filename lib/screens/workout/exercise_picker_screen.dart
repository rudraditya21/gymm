import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/categories.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  final void Function(Exercise) onSelect;

  const ExercisePickerScreen({super.key, required this.onSelect});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState
    extends ConsumerState<ExercisePickerScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(exerciseSearchProvider.notifier).state = '';
    ref.read(exerciseFilterProvider.notifier).state = null;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    ref.read(exerciseSearchProvider.notifier).state = '';
    ref.read(exerciseFilterProvider.notifier).state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedFilter = ref.watch(exerciseFilterProvider);
    final grouped = _groupByMuscle(exercises);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Add Exercise',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(exerciseSearchProvider.notifier).state = v,
                  style: GoogleFonts.dmSans(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search exercises…',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    prefixIcon: Icon(Icons.search,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: cs.secondary,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: selectedFilter == null,
                        onTap: () => ref
                            .read(exerciseFilterProvider.notifier)
                            .state = null,
                        cs: cs,
                      ),
                      ...MuscleGroup.filterGroups.map((g) => _FilterChip(
                            label: g,
                            selected: selectedFilter == g,
                            onTap: () => ref
                                .read(exerciseFilterProvider.notifier)
                                .state = g,
                            cs: cs,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: grouped.isEmpty
          ? Center(
              child: Text('No exercises found',
                  style: GoogleFonts.dmSans(
                      color: cs.onSurface.withValues(alpha: 0.5))))
          : ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final group = grouped[i];
                return _ExerciseGroup(
                  muscle: group.muscle,
                  exercises: group.exercises,
                  onSelect: (ex) {
                    widget.onSelect(ex);
                    Navigator.of(context).pop();
                  },
                  cs: cs,
                );
              },
            ),
    );
  }

  List<_Group> _groupByMuscle(List<Exercise> exercises) {
    final map = <String, List<Exercise>>{};
    for (final ex in exercises) {
      map.putIfAbsent(ex.primaryMuscle, () => []).add(ex);
    }
    return map.entries
        .map((e) => _Group(muscle: e.key, exercises: e.value))
        .toList()
      ..sort((a, b) => a.muscle.compareTo(b.muscle));
  }
}

class _Group {
  final String muscle;
  final List<Exercise> exercises;
  _Group({required this.muscle, required this.exercises});
}

class _ExerciseGroup extends StatelessWidget {
  final String muscle;
  final List<Exercise> exercises;
  final void Function(Exercise) onSelect;
  final ColorScheme cs;

  const _ExerciseGroup({
    required this.muscle,
    required this.exercises,
    required this.onSelect,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            muscle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        ...exercises.map((ex) => ListTile(
              onTap: () => onSelect(ex),
              title: Text(
                ex.name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                ex.equipment,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: ex.isCustom
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Custom',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : null,
            )),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
