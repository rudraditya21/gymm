import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../utils/muscle_intensity.dart';
import '../../widgets/body_painter.dart';

class MuscleHeatmapScreen extends ConsumerStatefulWidget {
  const MuscleHeatmapScreen({super.key});

  @override
  ConsumerState<MuscleHeatmapScreen> createState() =>
      _MuscleHeatmapScreenState();
}

class _MuscleHeatmapScreenState extends ConsumerState<MuscleHeatmapScreen> {
  bool _isFront = true;
  int _daysBack = 7; // 0 = all time

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);

    final cutoff = _daysBack == 0
        ? null
        : DateTime.now().subtract(Duration(days: _daysBack));
    final filtered = cutoff == null
        ? history
        : history.where((w) => w.startedAt.isAfter(cutoff)).toList();

    final intensities = computeMuscleIntensities(filtered);

    // Sorted breakdown list
    final sorted = intensities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Muscle Activity',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time window selector
            _SegmentRow(
              options: const {7: '7 days', 30: '30 days', 0: 'All time'},
              selected: _daysBack,
              onSelect: (v) => setState(() => _daysBack = v),
              cs: cs,
            ),
            const SizedBox(height: 12),

            // Front / Back toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PillToggle(
                  label: 'Front',
                  selected: _isFront,
                  onTap: () => setState(() => _isFront = true),
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _PillToggle(
                  label: 'Back',
                  selected: !_isFront,
                  onTap: () => setState(() => _isFront = false),
                  cs: cs,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Body diagram
            Center(
              child: SizedBox(
                width: 200,
                height: 460,
                child: CustomPaint(
                  painter: BodyHeatmapPainter(
                    intensities: intensities,
                    isFront: _isFront,
                    primaryColor: cs.primary,
                    surfaceColor: cs.secondary,
                    outlineColor: cs.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend
            _Legend(primary: cs.primary, cs: cs),
            const SizedBox(height: 28),

            if (intensities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No workout data for this period.\nLog some workouts to see muscle coverage.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      height: 1.6,
                    ),
                  ),
                ),
              )
            else ...[
              Text(
                'BREAKDOWN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 10),
              ...sorted.map(
                (e) => _MuscleBar(name: e.key, intensity: e.value, cs: cs),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Segment row ───────────────────────────────────────────────────────────────

class _SegmentRow extends StatelessWidget {
  final Map<int, String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final ColorScheme cs;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: options.entries.map((e) {
          final active = e.key == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: active ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pill toggle ───────────────────────────────────────────────────────────────

class _PillToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _PillToggle({
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
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? cs.onPrimary
                : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color primary;
  final ColorScheme cs;

  const _Legend({required this.primary, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Rested',
          style: GoogleFonts.poppins(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.4)),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (i) {
          final alpha = 0.07 + i * 0.185;
          return Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: cs.onSurface.withValues(alpha: 0.1),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'Heavy',
          style: GoogleFonts.poppins(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

// ── Muscle bar ────────────────────────────────────────────────────────────────

class _MuscleBar extends StatelessWidget {
  final String name;
  final double intensity;
  final ColorScheme cs;

  const _MuscleBar({
    required this.name,
    required this.intensity,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: cs.secondary,
                  ),
                  FractionallySizedBox(
                    widthFactor: intensity.clamp(0.02, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(
                            alpha: 0.55 + intensity * 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(intensity * 100).round()}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
