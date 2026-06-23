import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

// Display: Instrument Serif  (serif, dramatic, large scale only)
// Body/UI: Poppins            (geometric sans, all sizes)
// Mono:    system monospace   (technical labels)

abstract final class AppTextStyles {
  // ── Display ────────────────────────────────────────────────────────────────

  /// 96px · hero page declaration scale
  static TextStyle get heroDisplay => GoogleFonts.instrumentSerif(
        fontSize: 96,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.92,
        height: 1.0,
        color: AppLightColors.foreground,
      );

  /// 72px · product and research hero headlines
  static TextStyle get productDisplay => GoogleFonts.instrumentSerif(
        fontSize: 72,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.44,
        height: 1.0,
        color: AppLightColors.foreground,
      );

  /// 60px · large product-page headings
  static TextStyle get sectionDisplay => GoogleFonts.poppins(
        fontSize: 60,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.2,
        height: 1.0,
        color: AppLightColors.foreground,
      );

  // ── Headings ───────────────────────────────────────────────────────────────

  /// 48px · split hero and CTA headings
  static TextStyle get sectionHeading => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.48,
        height: 1.2,
        color: AppLightColors.foreground,
      );

  /// 32px · feature card and list section titles
  static TextStyle get cardHeading => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        height: 1.2,
        color: AppLightColors.foreground,
      );

  /// 24px · cards, filters, article titles
  static TextStyle get featureHeading => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppLightColors.foreground,
      );

  // ── Body ───────────────────────────────────────────────────────────────────

  /// 18px · lead text and larger paragraphs
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppLightColors.foreground,
      );

  /// 16px · default copy and link text
  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppLightColors.foreground,
      );

  // ── Labels & Utility ──────────────────────────────────────────────────────

  /// 14px · compact CTA labels
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.71,
        color: AppLightColors.foreground,
      );

  /// 14px · metadata and small explanatory text
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppLightColors.mutedForeground,
      );

  /// 14px · uppercase technical / system markers (mono)
  static const TextStyle monoLabel = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.28,
    height: 1.4,
    color: AppLightColors.mutedForeground,
  );

  /// 12px · footer, nav microcopy, small links
  static TextStyle get micro => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppLightColors.mutedForeground,
      );
}
