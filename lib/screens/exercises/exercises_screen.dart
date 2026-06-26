import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/categories.dart';
import '../../providers/exercise_provider.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Reset filters on exit
    Future.microtask(() {
      ref.read(exerciseSearchProvider.notifier).state = '';
      ref.read(exerciseFilterProvider.notifier).state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedFilter = ref.watch(exerciseFilterProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateExerciseScreen()),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Text(
                'Exercises',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    ref.read(exerciseSearchProvider.notifier).state = v,
                style:
                    GoogleFonts.poppins(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: GoogleFonts.poppins(
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
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Chip(
                    label: 'All',
                    selected: selectedFilter == null,
                    onTap: () => ref
                        .read(exerciseFilterProvider.notifier)
                        .state = null,
                    cs: cs,
                  ),
                  ...MuscleGroup.filterGroups.map((g) => _Chip(
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
            const SizedBox(height: 8),
            Expanded(
              child: exercises.isEmpty
                  ? Center(
                      child: Text('No results',
                          style: GoogleFonts.poppins(
                              color: cs.onSurface.withValues(alpha: 0.4))))
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (_, i) {
                        final ex = exercises[i];
                        return ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailScreen(exerciseId: ex.id),
                            ),
                          ),
                          title: Text(
                            ex.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${ex.primaryMuscle} · ${ex.equipment}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          trailing: ex.isCustom
                              ? PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4),
                                      size: 20),
                                  onSelected: (val) async {
                                    if (val == 'delete') {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Delete Exercise?'),
                                          content: const Text(
                                              'This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: Text('Delete',
                                                  style: TextStyle(
                                                      color: cs.error)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        ref
                                            .read(exercisesProvider.notifier)
                                            .delete(ex.id);
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style: TextStyle(color: cs.error)),
                                    ),
                                  ],
                                )
                              : Icon(
                                  Icons.chevron_right,
                                  color: cs.onSurface.withValues(alpha: 0.3),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _Chip({
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
          border: Border.all(color: selected ? cs.primary : cs.outline),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
