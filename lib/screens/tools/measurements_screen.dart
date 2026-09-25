import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/measurement_entry.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/settings_provider.dart';

double _toDisplay(double cm, bool useCm) =>
    useCm ? cm : cm * 0.393701;

String _fmtVal(double cm, bool useCm) {
  final v = _toDisplay(cm, useCm);
  final unit = useCm ? 'cm' : 'in';
  return v % 1 == 0
      ? '${v.toInt()} $unit'
      : '${v.toStringAsFixed(1)} $unit';
}

class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(measurementProvider);
    final useCm = ref.watch(settingsProvider).useCm;

    // Latest value per body part
    final latest = <String, MeasurementEntry>{};
    for (final e in all) {
      final cur = latest[e.bodyPart];
      if (cur == null || e.date.isAfter(cur.date)) latest[e.bodyPart] = e;
    }

    // Previous value per body part (second-latest)
    final prev = <String, MeasurementEntry>{};
    for (final part in kBodyParts) {
      final entries = all.where((e) => e.bodyPart == part).toList();
      if (entries.length >= 2) prev[part] = entries[entries.length - 2];
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Body Measurements',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kBodyParts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final part = kBodyParts[i];
          final l = latest[part];
          final p = prev[part];

          double? delta;
          if (l != null && p != null) {
            delta = _toDisplay(l.valueCm, useCm) -
                _toDisplay(p.valueCm, useCm);
          }

          return _PartCard(
            part: part,
            latest: l,
            delta: delta,
            useCm: useCm,
            cs: cs,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    _MeasurementDetailScreen(bodyPart: part),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _PartCard extends StatelessWidget {
  final String part;
  final MeasurementEntry? latest;
  final double? delta;
  final bool useCm;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _PartCard({
    required this.part,
    required this.latest,
    required this.delta,
    required this.useCm,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unit = useCm ? 'cm' : 'in';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                part,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (latest == null)
              Text(
                '— $unit',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              )
            else ...[
              Text(
                _fmtVal(latest!.valueCm, useCm),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              if (delta != null && delta != 0) ...[
                const SizedBox(width: 6),
                Icon(
                  delta! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: delta! > 0
                      ? cs.error.withValues(alpha: 0.8)
                      : Colors.green.withValues(alpha: 0.8),
                ),
              ],
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ── Detail screen ─────────────────────────────────────────────────────────────

class _MeasurementDetailScreen extends ConsumerStatefulWidget {
  final String bodyPart;
  const _MeasurementDetailScreen({required this.bodyPart});

  @override
  ConsumerState<_MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState
    extends ConsumerState<_MeasurementDetailScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addEntry(bool useCm) async {
    _ctrl.clear();
    final unit = useCm ? 'cm' : 'in';
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log ${widget.bodyPart} ($unit)'),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            hintText: '0.0',
            suffixText: unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(_ctrl.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;
    // Always store in cm
    final cm = useCm ? result : result / 0.393701;
    final today = DateTime.now();
    await ref.read(measurementProvider.notifier).add(
          widget.bodyPart,
          DateTime(today.year, today.month, today.day),
          cm,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final useCm = ref.watch(settingsProvider).useCm;
    final entries = ref
        .watch(measurementProvider)
        .where((e) => e.bodyPart == widget.bodyPart)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.bodyPart,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: cs.primary),
            onPressed: () => _addEntry(useCm),
          ),
        ],
      ),
      body: entries.isEmpty
          ? _Empty(cs: cs, onAdd: () => _addEntry(useCm))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsRow(entries: entries, useCm: useCm, cs: cs),
                const SizedBox(height: 20),
                _Chart(entries: entries, useCm: useCm, cs: cs),
                const SizedBox(height: 24),
                Text(
                  'HISTORY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                ...entries.reversed.map((e) => _EntryRow(
                      entry: e,
                      useCm: useCm,
                      cs: cs,
                      onDelete: () => ref
                          .read(measurementProvider.notifier)
                          .remove(e.bodyPart, e.date),
                    )),
              ],
            ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<MeasurementEntry> entries;
  final bool useCm;
  final ColorScheme cs;
  const _StatsRow({required this.entries, required this.useCm, required this.cs});

  @override
  Widget build(BuildContext context) {
    final minV =
        entries.map((e) => e.valueCm).reduce((a, b) => a < b ? a : b);
    final maxV =
        entries.map((e) => e.valueCm).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          _Cell(label: 'Current', value: _fmtVal(entries.last.valueCm, useCm),
              highlight: true, cs: cs),
          _Cell(label: 'Min', value: _fmtVal(minV, useCm), cs: cs),
          _Cell(label: 'Max', value: _fmtVal(maxV, useCm), cs: cs),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final ColorScheme cs;
  const _Cell(
      {required this.label,
      required this.value,
      required this.cs,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: highlight ? cs.primary : cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line chart ────────────────────────────────────────────────────────────────

class _Chart extends StatelessWidget {
  final List<MeasurementEntry> entries;
  final bool useCm;
  final ColorScheme cs;
  const _Chart({required this.entries, required this.useCm, required this.cs});

  @override
  Widget build(BuildContext context) {
    final spots = entries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), _toDisplay(e.value.valueCm, useCm)))
        .toList();

    final ys = spots.map((s) => s.y).toList();
    final rawMin = ys.reduce((a, b) => a < b ? a : b);
    final rawMax = ys.reduce((a, b) => a > b ? a : b);
    final minY = rawMin - 2;
    final maxY = rawMax + 2;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: LineChart(
        LineChartData(
          minX: -0.3,
          maxX: spots.last.x + 0.3,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.none(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outline.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 2,
              curveSmoothness: 0.3,
              color: cs.primary,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: cs.primary,
                  strokeWidth: 2,
                  strokeColor: cs.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha: 0.18),
                    cs.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History row ───────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final MeasurementEntry entry;
  final bool useCm;
  final ColorScheme cs;
  final VoidCallback onDelete;

  const _EntryRow(
      {required this.entry, required this.useCm, required this.cs, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = entry.date;
    final dateStr = '${_month(d.month)} ${d.day}, ${d.year}';
    final v = _fmtVal(entry.valueCm, useCm);

    return Dismissible(
      key: ValueKey('${entry.bodyPart}_${entry.date.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error.withValues(alpha: 0.12),
        child: Icon(Icons.delete_outline, color: cs.error, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              dateStr,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              v,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _month(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onAdd;
  const _Empty({required this.cs, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten_outlined,
              size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No entries yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Log Measurement'),
          ),
        ],
      ),
    );
  }
}
