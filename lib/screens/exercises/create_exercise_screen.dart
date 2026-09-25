import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/categories.dart';
import '../../providers/exercise_provider.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _nameCtrl = TextEditingController();
  String _primaryMuscle = MuscleGroup.chest;
  String _equipment = Equipment.barbell;
  final _secondary = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }
    setState(() => _saving = true);
    await ref.read(exercisesProvider.notifier).addCustom(
          name: name,
          primaryMuscle: _primaryMuscle,
          secondaryMuscles: _secondary.toList(),
          equipment: _equipment,
        );
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
        title: Text('New Exercise',
            style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _saving
                        ? cs.onSurface.withValues(alpha: 0.3)
                        : cs.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Label('NAME', cs),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: GoogleFonts.dmSans(fontSize: 15, color: cs.onSurface),
            decoration: _fieldDecor('e.g. Incline Cable Fly', cs),
          ),
          const SizedBox(height: 24),

          _Label('PRIMARY MUSCLE', cs),
          const SizedBox(height: 8),
          _PickerTile(
            value: _primaryMuscle,
            options: MuscleGroup.all,
            cs: cs,
            onChanged: (v) => setState(() => _primaryMuscle = v),
          ),
          const SizedBox(height: 24),

          _Label('EQUIPMENT', cs),
          const SizedBox(height: 8),
          _PickerTile(
            value: _equipment,
            options: const [
              Equipment.barbell,
              Equipment.dumbbell,
              Equipment.cable,
              Equipment.machine,
              Equipment.bodyweight,
              Equipment.band,
              Equipment.kettlebell,
              Equipment.other,
            ],
            cs: cs,
            onChanged: (v) => setState(() => _equipment = v),
          ),
          const SizedBox(height: 24),

          _Label('SECONDARY MUSCLES (optional)', cs),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MuscleGroup.all
                .where((m) => m != _primaryMuscle)
                .map((m) {
              final selected = _secondary.contains(m);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _secondary.remove(m);
                  } else {
                    _secondary.add(m);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : cs.secondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected ? cs.primary : cs.outline),
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          selected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecor(String hint, ColorScheme cs) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 15, color: cs.onSurface.withValues(alpha: 0.3)),
        filled: true,
        fillColor: cs.secondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );
}

class _Label extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _Label(this.text, this.cs);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
      );
}

class _PickerTile extends StatelessWidget {
  final String value;
  final List<String> options;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  const _PickerTile({
    required this.value,
    required this.options,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select'),
            children: options
                .map((o) => SimpleDialogOption(
                      onPressed: () => Navigator.of(ctx).pop(o),
                      child: Text(o,
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: o == value
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ))
                .toList(),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: cs.onSurface)),
            const Spacer(),
            Icon(Icons.expand_more,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
