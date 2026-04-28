import 'package:flutter/material.dart';

import '../constants/colors.dart';

// Display font: Space Grotesk (fallback for CohereText)
// Body/UI font: Inter (fallback for Unica77)
// Mono font:    system monospace (fallback for CohereMono)
const String _display = 'SpaceGrotesk';
const String _body = 'Inter';
const String _mono = 'monospace';

abstract final class AppTextStyles {
  // ── Display ────────────────────────────────────────────────────────────────

  /// 96px · hero page declaration scale
  static const TextStyle heroDisplay = TextStyle(
    fontFamily: _display,
    fontSize: 96,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.92,
    height: 1.0,
    color: AppColors.ink,
  );

  /// 72px · product and research hero headlines
  static const TextStyle productDisplay = TextStyle(
    fontFamily: _display,
    fontSize: 72,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.44,
    height: 1.0,
    color: AppColors.ink,
  );

  /// 60px · large product-page headings
  static const TextStyle sectionDisplay = TextStyle(
    fontFamily: _body,
    fontSize: 60,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.2,
    height: 1.0,
    color: AppColors.ink,
  );

  // ── Headings ───────────────────────────────────────────────────────────────

  /// 48px · split hero and CTA headings
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: _body,
    fontSize: 48,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.48,
    height: 1.2,
    color: AppColors.ink,
  );

  /// 32px · feature card and list section titles
  static const TextStyle cardHeading = TextStyle(
    fontFamily: _body,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.2,
    color: AppColors.ink,
  );

  /// 24px · cards, filters, article titles
  static const TextStyle featureHeading = TextStyle(
    fontFamily: _body,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.ink,
  );

  // ── Body ───────────────────────────────────────────────────────────────────

  /// 18px · lead text and larger paragraphs
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _body,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.ink,
  );

  /// 16px · default copy and link text
  static const TextStyle body = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.ink,
  );

  // ── Labels & Utility ──────────────────────────────────────────────────────

  /// 14px · compact CTA labels
  static const TextStyle button = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.71,
    color: AppColors.ink,
  );

  /// 14px · metadata and small explanatory text
  static const TextStyle caption = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.mutedSlate,
  );

  /// 14px · uppercase technical / system markers (mono)
  static const TextStyle monoLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.28,
    height: 1.4,
    color: AppColors.mutedSlate,
  );

  /// 12px · footer, nav microcopy, small links
  static const TextStyle micro = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.mutedSlate,
  );
}
