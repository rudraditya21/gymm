import 'package:flutter/material.dart';

/// Single painter for both front and back body views.
/// All coordinates are expressed as fractions of [canvas size],
/// so the diagram scales to any widget size.
class BodyHeatmapPainter extends CustomPainter {
  final Map<String, double> intensities;
  final bool isFront;
  final Color primaryColor;
  final Color surfaceColor;  // body silhouette fill
  final Color outlineColor;  // muscle region stroke

  const BodyHeatmapPainter({
    required this.intensities,
    required this.isFront,
    required this.primaryColor,
    required this.surfaceColor,
    required this.outlineColor,
  });

  // ── Paint ──────────────────────────────────────────────────────────────────

  Paint _fill(String key) {
    final intensity = intensities[key] ?? 0.0;
    final color = intensity > 0
        ? primaryColor.withValues(alpha: (0.20 + intensity * 0.72).clamp(0.0, 0.92))
        : outlineColor.withValues(alpha: 0.07);
    return Paint()..color = color..style = PaintingStyle.fill;
  }

  Paint get _stroke => Paint()
    ..color = outlineColor.withValues(alpha: 0.18)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  Paint get _bodyFill => Paint()
    ..color = surfaceColor
    ..style = PaintingStyle.fill;

  // ── Top-level paint ────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _silhouette(canvas, w, h);
    if (isFront) {
      _frontMuscles(canvas, w, h);
    } else {
      _backMuscles(canvas, w, h);
    }
  }

  // ── Body silhouette ────────────────────────────────────────────────────────

  void _silhouette(Canvas canvas, double w, double h) {
    // Draw legs first so torso caps their tops naturally.
    _rr(canvas, _bodyFill, w * 0.280, h * 0.545, w * 0.192, h * 0.445, 10);
    _rr(canvas, _bodyFill, w * 0.528, h * 0.545, w * 0.192, h * 0.445, 10);

    // Arms
    _quad(canvas, _bodyFill,
        Offset(w * 0.155, h * 0.160), Offset(w * 0.248, h * 0.152),
        Offset(w * 0.195, h * 0.565), Offset(w * 0.092, h * 0.565));
    _quad(canvas, _bodyFill,
        Offset(w * 0.752, h * 0.152), Offset(w * 0.845, h * 0.160),
        Offset(w * 0.908, h * 0.565), Offset(w * 0.805, h * 0.565));

    // Torso (trapeziod, wider at top / shoulders, slight hourglass)
    _quad(canvas, _bodyFill,
        Offset(w * 0.240, h * 0.152), Offset(w * 0.760, h * 0.152),
        Offset(w * 0.700, h * 0.565), Offset(w * 0.300, h * 0.565));

    // Neck
    _rr(canvas, _bodyFill, w * 0.430, h * 0.112, w * 0.140, h * 0.048, 4);

    // Head
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.500, h * 0.064),
          width: w * 0.270,
          height: h * 0.112),
      _bodyFill,
    );
  }

  // ── Front muscles ──────────────────────────────────────────────────────────

  void _frontMuscles(Canvas canvas, double w, double h) {
    // Shoulders (left + right)
    _oval(canvas, 'Shoulders', w * 0.195, h * 0.200, w * 0.078, h * 0.058);
    _oval(canvas, 'Shoulders', w * 0.805, h * 0.200, w * 0.078, h * 0.058);

    // Chest — two lobes
    _rr(canvas, _fill('Chest'),   w * 0.262, h * 0.162, w * 0.208, h * 0.118, 8);
    _rr(canvas, _fill('Chest'),   w * 0.530, h * 0.162, w * 0.208, h * 0.118, 8);
    _rr(canvas, _stroke,          w * 0.262, h * 0.162, w * 0.208, h * 0.118, 8);
    _rr(canvas, _stroke,          w * 0.530, h * 0.162, w * 0.208, h * 0.118, 8);

    // Biceps
    _rr2(canvas, 'Biceps', w * 0.093, h * 0.268, w * 0.092, h * 0.132, 6);
    _rr2(canvas, 'Biceps', w * 0.815, h * 0.268, w * 0.092, h * 0.132, 6);

    // Forearms
    _rr2(canvas, 'Forearms', w * 0.088, h * 0.408, w * 0.084, h * 0.138, 6);
    _rr2(canvas, 'Forearms', w * 0.828, h * 0.408, w * 0.084, h * 0.138, 6);

    // Core / Abs
    _rr2(canvas, 'Core', w * 0.340, h * 0.282, w * 0.320, h * 0.268, 6);

    // Quads
    _rr2(canvas, 'Quadriceps', w * 0.286, h * 0.568, w * 0.182, h * 0.222, 8);
    _rr2(canvas, 'Quadriceps', w * 0.532, h * 0.568, w * 0.182, h * 0.222, 8);

    // Calves (front)
    _rr2(canvas, 'Calves', w * 0.292, h * 0.798, w * 0.162, h * 0.180, 6);
    _rr2(canvas, 'Calves', w * 0.546, h * 0.798, w * 0.162, h * 0.180, 6);
  }

  // ── Back muscles ───────────────────────────────────────────────────────────

  void _backMuscles(Canvas canvas, double w, double h) {
    // Rear Shoulders
    _oval(canvas, 'Shoulders', w * 0.195, h * 0.200, w * 0.078, h * 0.058);
    _oval(canvas, 'Shoulders', w * 0.805, h * 0.200, w * 0.078, h * 0.058);

    // Back — traps + lats as one big region
    _path2(canvas, 'Back', [
      Offset(w * 0.278, h * 0.158), Offset(w * 0.722, h * 0.158),
      Offset(w * 0.670, h * 0.558), Offset(w * 0.330, h * 0.558),
    ]);

    // Triceps
    _rr2(canvas, 'Triceps', w * 0.088, h * 0.262, w * 0.094, h * 0.148, 6);
    _rr2(canvas, 'Triceps', w * 0.818, h * 0.262, w * 0.094, h * 0.148, 6);

    // Forearms
    _rr2(canvas, 'Forearms', w * 0.088, h * 0.418, w * 0.084, h * 0.132, 6);
    _rr2(canvas, 'Forearms', w * 0.828, h * 0.418, w * 0.084, h * 0.132, 6);

    // Glutes
    _path2(canvas, 'Glutes', [
      Offset(w * 0.288, h * 0.555), Offset(w * 0.712, h * 0.555),
      Offset(w * 0.702, h * 0.662), Offset(w * 0.298, h * 0.662),
    ]);

    // Hamstrings
    _rr2(canvas, 'Hamstrings', w * 0.288, h * 0.662, w * 0.182, h * 0.188, 8);
    _rr2(canvas, 'Hamstrings', w * 0.530, h * 0.662, w * 0.182, h * 0.188, 8);

    // Calves (back)
    _rr2(canvas, 'Calves', w * 0.292, h * 0.858, w * 0.162, h * 0.128, 6);
    _rr2(canvas, 'Calves', w * 0.546, h * 0.858, w * 0.162, h * 0.128, 6);
  }

  // ── Draw primitives ────────────────────────────────────────────────────────

  /// Filled + stroked oval for a muscle key.
  void _oval(Canvas canvas, String key, double cx, double cy,
      double rx, double ry) {
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    canvas.drawOval(rect, _fill(key));
    canvas.drawOval(rect, _stroke);
  }

  /// Filled + stroked RRect for a muscle key (uses _fill internally).
  void _rr2(Canvas canvas, String key, double l, double t, double w, double h,
      double r) {
    final rr =
        RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));
    canvas.drawRRect(rr, _fill(key));
    canvas.drawRRect(rr, _stroke);
  }

  /// Filled + stroked path for a muscle key.
  void _path2(Canvas canvas, String key, List<Offset> pts) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final pt in pts.skip(1)) { p.lineTo(pt.dx, pt.dy); }
    p.close();
    canvas.drawPath(p, _fill(key));
    canvas.drawPath(p, _stroke);
  }

  /// Bare filled RRect (for silhouette parts).
  void _rr(Canvas canvas, Paint paint, double l, double t, double w, double h,
      double r) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(l, t, w, h), Radius.circular(r)),
        paint);
  }

  /// Bare filled quadrilateral (for silhouette parts).
  void _quad(Canvas canvas, Paint paint, Offset tl, Offset tr,
      Offset br, Offset bl) {
    canvas.drawPath(
        Path()
          ..moveTo(tl.dx, tl.dy)
          ..lineTo(tr.dx, tr.dy)
          ..lineTo(br.dx, br.dy)
          ..lineTo(bl.dx, bl.dy)
          ..close(),
        paint);
  }

  @override
  bool shouldRepaint(BodyHeatmapPainter old) =>
      old.intensities != intensities || old.isFront != isFront;
}
