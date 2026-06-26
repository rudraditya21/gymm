import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_workout.dart';

typedef OnSetComplete = void Function(double? weight, int? reps);

class SetRow extends StatefulWidget {
  final ActiveSet set;
  final bool useKg;
  final OnSetComplete onComplete;
  final VoidCallback onRemove;

  const SetRow({
    super.key,
    required this.set,
    required this.useKg,
    required this.onComplete,
    required this.onRemove,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: _weightText(widget.set.weight, widget.useKg),
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    // Only sync if the value changed externally (e.g. set was re-added)
    if (old.set.index != widget.set.index) {
      _weightCtrl.text = _weightText(widget.set.weight, widget.useKg);
      _repsCtrl.text = widget.set.reps?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  String _weightText(double? w, bool useKg) {
    if (w == null) return '';
    final v = useKg ? w : w * 2.20462;
    if (v == v.truncateToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(1);
  }

  double? _parseWeight(String text) {
    final v = double.tryParse(text);
    if (v == null) return null;
    return widget.useKg ? v : v / 2.20462;
  }

  void _onCheck() {
    final weight = _parseWeight(_weightCtrl.text.trim());
    final reps = int.tryParse(_repsCtrl.text.trim());
    widget.onComplete(weight, reps);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final set = widget.set;
    final completed = set.isCompleted;
    final unit = widget.useKg ? 'kg' : 'lb';

    final rowColor = completed
        ? cs.primary.withValues(alpha: 0.06)
        : Colors.transparent;

    final prevText = (set.prevWeight != null && set.prevReps != null)
        ? '${_weightText(set.prevWeight, widget.useKg)}×${set.prevReps}'
        : '–';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Set number / warmup indicator
          GestureDetector(
            onLongPress: widget.onRemove,
            child: SizedBox(
              width: 28,
              child: Text(
                set.isWarmup ? 'W' : '${set.index + 1}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: set.isWarmup
                      ? cs.primary.withValues(alpha: 0.6)
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          // Previous performance
          SizedBox(
            width: 60,
            child: Text(
              prevText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Weight field
          Expanded(
            flex: 3,
            child: _NumberField(
              controller: _weightCtrl,
              hint: unit,
              decimal: true,
              completed: completed,
              cs: cs,
            ),
          ),
          const SizedBox(width: 8),
          // Reps field
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _repsCtrl,
              hint: 'reps',
              decimal: false,
              completed: completed,
              cs: cs,
            ),
          ),
          const SizedBox(width: 8),
          // Complete button
          GestureDetector(
            onTap: _onCheck,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: completed ? cs.primary : cs.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                completed ? Icons.check_rounded : Icons.check_rounded,
                size: 18,
                color: completed
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final bool completed;
  final ColorScheme cs;

  const _NumberField({
    required this.controller,
    required this.hint,
    required this.decimal,
    required this.completed,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: completed
            ? cs.onSurface.withValues(alpha: 0.55)
            : cs.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.25),
        ),
        filled: true,
        fillColor: cs.secondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
