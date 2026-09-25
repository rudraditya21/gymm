import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_workout.dart';

typedef OnSetComplete = void Function(
    double? weight, int? reps, int? durationSeconds, double? distanceMeters);

class SetRow extends StatefulWidget {
  final ActiveSet set;
  final bool useKg;
  final bool isCardio;
  final bool isBodyweight;
  final OnSetComplete onComplete;
  final VoidCallback onRemove;
  final VoidCallback onCycleType;

  const SetRow({
    super.key,
    required this.set,
    required this.useKg,
    required this.isCardio,
    this.isBodyweight = false,
    required this.onComplete,
    required this.onRemove,
    required this.onCycleType,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _primaryCtrl;  // weight or duration-min
  late TextEditingController _secondaryCtrl; // reps or distance-km
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _primaryCtrl = TextEditingController(text: _primaryText());
    _secondaryCtrl = TextEditingController(text: _secondaryText());
  }

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    if (old.set.index != widget.set.index) {
      _primaryCtrl.text = _primaryText();
      _secondaryCtrl.text = _secondaryText();
    }
  }

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  String _primaryText() {
    if (widget.isCardio) {
      final secs = widget.set.durationSeconds;
      return secs != null ? '${secs ~/ 60}' : '';
    }
    return _weightText(widget.set.weight, widget.useKg);
  }

  String _secondaryText() {
    if (widget.isCardio) {
      final m = widget.set.distanceMeters;
      return m != null ? (m / 1000).toStringAsFixed(2) : '';
    }
    return widget.set.reps?.toString() ?? '';
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
    if (widget.isCardio) {
      final mins = int.tryParse(_primaryCtrl.text.trim());
      final km = double.tryParse(_secondaryCtrl.text.trim());
      if (!widget.set.isCompleted &&
          (mins == null || mins <= 0 || km == null || km <= 0)) {
        setState(
            () => _validationError = 'Enter a positive duration and distance.');
        return;
      }
      setState(() => _validationError = null);
      widget.onComplete(null, null, mins != null ? mins * 60 : null,
          km != null ? km * 1000 : null);
    } else {
      final weight = _parseWeight(_primaryCtrl.text.trim());
      final reps = int.tryParse(_secondaryCtrl.text.trim());
      final hasInvalidWeight =
          _primaryCtrl.text.trim().isNotEmpty && weight == null;
      if (!widget.set.isCompleted &&
          (hasInvalidWeight || reps == null || reps <= 0)) {
        setState(
            () => _validationError = 'Enter a valid weight and positive reps.');
        return;
      }
      setState(() => _validationError = null);
      widget.onComplete(weight, reps, null, null);
    }
  }

  void _clearValidationError(String _) {
    if (_validationError != null) setState(() => _validationError = null);
  }

  static String _typeLabel(ActiveSet set) {
    switch (set.setType) {
      case SetType.warmup:
        return 'W';
      case SetType.dropSet:
        return 'D';
      case SetType.amrap:
        return 'F';
      case SetType.normal:
        return '${set.index + 1}';
    }
  }

  static Color _typeColor(ActiveSet set, ColorScheme cs) {
    switch (set.setType) {
      case SetType.warmup:
        return cs.primary.withValues(alpha: 0.6);
      case SetType.dropSet:
        return Colors.orange.withValues(alpha: 0.8);
      case SetType.amrap:
        return Colors.red.withValues(alpha: 0.7);
      case SetType.normal:
        return cs.onSurface.withValues(alpha: 0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final set = widget.set;
    final completed = set.isCompleted;

    final rowColor = completed
        ? cs.primary.withValues(alpha: 0.06)
        : Colors.transparent;

    String prevText;
    if (widget.isCardio) {
      prevText = '–';
    } else if (set.prevReps != null) {
      final w = set.prevWeight != null
          ? _weightText(set.prevWeight, widget.useKg)
          : (widget.isBodyweight ? 'BW' : '–');
      prevText = '$w×${set.prevReps}';
    } else {
      prevText = '–';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          // Set type indicator — tap to cycle, long-press to remove
          GestureDetector(
            onTap: widget.onCycleType,
            onLongPress: widget.onRemove,
            child: SizedBox(
              width: 28,
              child: Text(
                _typeLabel(set),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _typeColor(set, cs),
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
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Primary field (weight or minutes)
          Expanded(
            flex: 3,
            child: _NumberField(
              controller: _primaryCtrl,
              hint: widget.isCardio
                  ? 'min'
                  : widget.isBodyweight
                      ? (widget.useKg ? '+kg' : '+lb')
                      : (widget.useKg ? 'kg' : 'lb'),
              decimal: !widget.isCardio,
              completed: completed,
              cs: cs,
              onChanged: _clearValidationError,
            ),
          ),
          const SizedBox(width: 8),
          // Secondary field (reps or km)
          Expanded(
            flex: 2,
            child: _NumberField(
              controller: _secondaryCtrl,
              hint: widget.isCardio ? 'km' : 'reps',
              decimal: widget.isCardio,
              completed: completed,
              cs: cs,
              onChanged: _clearValidationError,
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
                Icons.check_rounded,
                size: 18,
                color: completed
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
            ],
          ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(left: 88, top: 4),
              child: Text(
                _validationError!,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: cs.error,
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
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.controller,
    required this.hint,
    required this.decimal,
    required this.completed,
    required this.cs,
    this.onChanged,
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
      onChanged: onChanged,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        color: completed
            ? cs.onSurface.withValues(alpha: 0.55)
            : cs.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
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
