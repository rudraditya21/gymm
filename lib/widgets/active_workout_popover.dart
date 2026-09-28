import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_workout.dart';

class ActiveWorkoutPopover extends StatefulWidget {
  final ActiveWorkoutState workout;
  final VoidCallback onTap;

  const ActiveWorkoutPopover({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  State<ActiveWorkoutPopover> createState() => _ActiveWorkoutPopoverState();
}

class _ActiveWorkoutPopoverState extends State<ActiveWorkoutPopover> {
  late final Timer _timer;

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
    final elapsed = DateTime.now().difference(widget.workout.startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final time = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: cs.onPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 14, color: cs.onPrimary),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.dmSans(fontSize: 14, color: cs.onPrimary),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: cs.onPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
