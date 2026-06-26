import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../utils/muscle_intensity.dart';

// Fixed ordered axes — order matters for radar shape consistency.
const _axes = [
  'Chest',
  'Shoulders',
  'Triceps',
  'Back',
  'Biceps',
  'Forearms',
  'Core',
  'Quadriceps',
  'Hamstrings',
  'Glutes',
  'Calves',
];

class MuscleHeatmapScreen extends ConsumerStatefulWidget {
  const MuscleHeatmapScreen({super.key});

  @override
  ConsumerState<MuscleHeatmapScreen> createState() =>
      _MuscleHeatmapScreenState();
}

class _MuscleHeatmapScreenState extends ConsumerState<MuscleHeatmapScreen> {
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
            _SegmentRow(
              options: const {7: '7 days', 30: '30 days', 0: 'All time'},
              selected: _daysBack,
              onSelect: (v) => setState(() => _daysBack = v),
              cs: cs,
            ),
            const SizedBox(height: 24),

            if (intensities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.accessibility_new,
                        size: 48,
                        color: cs.onSurface.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Text(
                      'No workout data for this period.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _RadarCard(intensities: intensities, cs: cs),
              const SizedBox(height: 28),
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

// ── Radar card ────────────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final Map<String, double> intensities;
  final ColorScheme cs;

  const _RadarCard({required this.intensities, required this.cs});

  @override
  Widget build(BuildContext context) {
    final values =
        _axes.map((k) => RadarEntry(value: intensities[k] ?? 0.0)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            dataSets: [
              RadarDataSet(
                dataEntries: values,
                fillColor: cs.primary.withValues(alpha: 0.22),
                borderColor: cs.primary,
                borderWidth: 2.0,
                entryRadius: 4,
              ),
            ],
            radarBackgroundColor: Colors.transparent,
            radarBorderData: BorderSide(
              color: cs.outline.withValues(alpha: 0.25),
              width: 1,
            ),
            tickCount: 4,
            ticksTextStyle: const TextStyle(
              color: Colors.transparent,
              fontSize: 0,
            ),
            tickBorderData: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
            gridBorderData: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            getTitle: (index, angle) =>
                RadarChartTitle(text: _axes[index], angle: 0),
            titlePositionPercentageOffset: 0.12,
          ),
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
            width: 110,
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
                  Container(height: 8, color: cs.secondary),
                  FractionallySizedBox(
                    widthFactor: intensity.clamp(0.02, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary
                            .withValues(alpha: 0.55 + intensity * 0.45),
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
