import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/rest_timer_provider.dart';

class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RestTimerState>(restTimerProvider, (prev, next) {
      if (prev != null &&
          prev.isRunning &&
          !next.isRunning &&
          next.remaining == 0) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150),
            () => HapticFeedback.heavyImpact());
      }
    });
    final timer = ref.watch(restTimerProvider);
    if (!timer.isRunning && timer.remaining == 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final m = timer.remaining ~/ 60;
    final s = timer.remaining % 60;
    final timeStr = '$m:${s.toString().padLeft(2, '0')}';

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              'REST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timer.progress,
                  backgroundColor: cs.outline,
                  color: cs.primary,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeStr,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            _TimerButton(
              label: '+30s',
              onTap: () => ref.read(restTimerProvider.notifier).addTime(30),
              cs: cs,
            ),
            const SizedBox(width: 8),
            _TimerButton(
              label: 'Skip',
              onTap: () => ref.read(restTimerProvider.notifier).skip(),
              cs: cs,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _TimerButton({
    required this.label,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}
