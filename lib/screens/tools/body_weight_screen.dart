import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/body_weight_entry.dart';
import '../../providers/body_weight_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';

class BodyWeightScreen extends ConsumerStatefulWidget {
  const BodyWeightScreen({super.key});

  @override
  ConsumerState<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends ConsumerState<BodyWeightScreen> {
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Widget _buildStatsRow(
    List<BodyWeightEntry> entries,
    String unit,
    bool useKg,
    ColorScheme cs,
  ) {
    final current = formatWeightNum(entries.last.weight, useKg: useKg);
    final minW = entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxW = entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'Current',
            value: '$current $unit',
            highlight: true,
            cs: cs,
          ),
          _StatCell(
            label: 'Min',
            value: '${formatWeightNum(minW, useKg: useKg)} $unit',
            cs: cs,
          ),
          _StatCell(
            label: 'Max',
            value: '${formatWeightNum(maxW, useKg: useKg)} $unit',
            cs: cs,
          ),
        ],
      ),
    );
  }

  Future<void> _addEntry(bool useKg) async {
    _weightCtrl.clear();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Weight (${useKg ? 'kg' : 'lb'})'),
        content: TextField(
          controller: _weightCtrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            hintText: useKg ? '75.0' : '165',
            suffixText: useKg ? 'kg' : 'lb',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(_weightCtrl.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;
    final today = DateTime.now();
    await ref.read(bodyWeightProvider.notifier).add(
          DateTime(today.year, today.month, today.day),
          result,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = ref.watch(bodyWeightProvider);
    final useKg = ref.watch(settingsProvider).useKg;
    final unit = useKg ? 'kg' : 'lb';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Body Weight',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: cs.primary),
            onPressed: () => _addEntry(useKg),
          ),
        ],
      ),
      body: entries.isEmpty
          ? _Empty(cs: cs, onAdd: () => _addEntry(useKg))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current / Min / Max
                _buildStatsRow(entries, unit, useKg, cs),
                const SizedBox(height: 20),

                // Graph
                _Chart(entries: entries, useKg: useKg, cs: cs),
                const SizedBox(height: 24),

                // History
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
                      useKg: useKg,
                      cs: cs,
                      onDelete: () => ref
                          .read(bodyWeightProvider.notifier)
                          .remove(e.date),
                    )),
              ],
            ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<BodyWeightEntry> entries;
  final bool useKg;
  final ColorScheme cs;

  const _Chart(
      {required this.entries, required this.useKg, required this.cs});

  @override
  Widget build(BuildContext context) {
    final spots = entries.asMap().entries.map((e) {
      final w = useKg ? e.value.weight : e.value.weight * 2.20462;
      return FlSpot(e.key.toDouble(), w);
    }).toList();

    final ys = spots.map((s) => s.y).toList();
    final rawMin = ys.reduce((a, b) => a < b ? a : b);
    final rawMax = ys.reduce((a, b) => a > b ? a : b);
    // Give a visible range even when all values are identical
    final minY = rawMin - 3;
    final maxY = rawMax + 3;

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

class _EntryRow extends StatelessWidget {
  final BodyWeightEntry entry;
  final bool useKg;
  final ColorScheme cs;
  final VoidCallback onDelete;

  const _EntryRow({
    required this.entry,
    required this.useKg,
    required this.cs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = entry.date;
    final dateStr =
        '${_monthName(d.month)} ${d.day}, ${d.year}';
    final unit = useKg ? 'kg' : 'lb';
    final w = formatWeightNum(entry.weight, useKg: useKg);

    return Dismissible(
      key: ValueKey(entry.date.millisecondsSinceEpoch),
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
              '$w $unit',
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

  static String _monthName(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final ColorScheme cs;

  const _StatCell({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
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
          Icon(Icons.monitor_weight_outlined,
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
            label: const Text('Log Weight'),
          ),
        ],
      ),
    );
  }
}
