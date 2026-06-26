import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/settings_provider.dart';

// Standard plate sizes in kg and lb
const _platesKg = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
const _platesLb = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];
const _barKg = 20.0;
const _barLb = 45.0;

class PlateCalculatorScreen extends ConsumerStatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  ConsumerState<PlateCalculatorScreen> createState() =>
      _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState
    extends ConsumerState<PlateCalculatorScreen> {
  final _ctrl = TextEditingController();
  double? _target;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<(double, int)> _calculate(double target, bool useKg) {
    final bar = useKg ? _barKg : _barLb;
    final plates = useKg ? _platesKg : _platesLb;
    var remaining = (target - bar) / 2;
    final result = <(double, int)>[];
    for (final p in plates) {
      if (remaining <= 0) break;
      final count = (remaining / p).floor();
      if (count > 0) {
        result.add((p, count));
        remaining -= count * p;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final useKg = ref.watch(settingsProvider).useKg;
    final bar = useKg ? _barKg : _barLb;
    final unit = useKg ? 'kg' : 'lb';

    final plates =
        _target != null && _target! > bar ? _calculate(_target!, useKg) : null;
    final loadedWeight = plates == null
        ? null
        : bar + plates.fold<double>(0, (s, e) => s + e.$1 * e.$2) * 2;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Plate Calculator',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input
            Text(
              'Target weight ($unit)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '100',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.2),
                ),
                suffix: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                filled: true,
                fillColor: cs.secondary,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() {
                _target = double.tryParse(v);
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Bar: $bar $unit',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 32),

            if (_target == null || _target! <= bar) ...[
              Center(
                child: Text(
                  _target != null && _target! <= bar
                      ? 'Target must be heavier than the bar ($bar $unit)'
                      : 'Enter a target weight above',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ] else if (plates != null) ...[
              Text(
                'PLATES PER SIDE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 12),
              ...plates.map((e) => _PlateRow(
                    weight: e.$1,
                    count: e.$2,
                    unit: unit,
                    cs: cs,
                  )),
              if (plates.isEmpty)
                Text(
                  'No standard plates fit — adjust target',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'Loaded weight',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${loadedWeight!.toStringAsFixed(loadedWeight % 1 == 0 ? 0 : 1)} $unit',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlateRow extends StatelessWidget {
  final double weight;
  final int count;
  final String unit;
  final ColorScheme cs;

  const _PlateRow({
    required this.weight,
    required this.count,
    required this.unit,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final w =
        weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              w,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$w $unit  ×  $count',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
