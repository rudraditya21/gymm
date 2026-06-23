import 'package:flutter/material.dart';

/// Shadcn "default" light-theme color tokens.
abstract final class AppLightColors {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const Color background           = Color(0xFFFFFFFF);
  static const Color foreground           = Color(0xFF020817);

  // ── Card ──────────────────────────────────────────────────────────────────
  static const Color card                 = Color(0xFFFFFFFF);
  static const Color cardForeground       = Color(0xFF020817);

  // ── Popover ───────────────────────────────────────────────────────────────
  static const Color popover              = Color(0xFFFFFFFF);
  static const Color popoverForeground    = Color(0xFF020817);

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary              = Color(0xFF0F172A);
  static const Color primaryForeground    = Color(0xFFF8FAFC);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary            = Color(0xFFF1F5F9);
  static const Color secondaryForeground  = Color(0xFF0F172A);

  // ── Muted ─────────────────────────────────────────────────────────────────
  static const Color muted                = Color(0xFFF1F5F9);
  static const Color mutedForeground      = Color(0xFF64748B);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent               = Color(0xFFF1F5F9);
  static const Color accentForeground     = Color(0xFF0F172A);

  // ── Destructive ───────────────────────────────────────────────────────────
  static const Color destructive          = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFF8FAFC);

  // ── Border / Input / Ring ─────────────────────────────────────────────────
  static const Color border               = Color(0xFFE2E8F0);
  static const Color input                = Color(0xFFE2E8F0);
  static const Color ring                 = Color(0xFF020817);
}

/// Shadcn "default" dark-theme color tokens.
abstract final class AppDarkColors {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const Color background           = Color(0xFF020817);
  static const Color foreground           = Color(0xFFF8FAFC);

  // ── Card ──────────────────────────────────────────────────────────────────
  static const Color card                 = Color(0xFF020817);
  static const Color cardForeground       = Color(0xFFF8FAFC);

  // ── Popover ───────────────────────────────────────────────────────────────
  static const Color popover              = Color(0xFF020817);
  static const Color popoverForeground    = Color(0xFFF8FAFC);

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary              = Color(0xFFF8FAFC);
  static const Color primaryForeground    = Color(0xFF0F172A);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary            = Color(0xFF1E293B);
  static const Color secondaryForeground  = Color(0xFFF8FAFC);

  // ── Muted ─────────────────────────────────────────────────────────────────
  static const Color muted                = Color(0xFF1E293B);
  static const Color mutedForeground      = Color(0xFF94A3B8);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent               = Color(0xFF1E293B);
  static const Color accentForeground     = Color(0xFFF8FAFC);

  // ── Destructive ───────────────────────────────────────────────────────────
  static const Color destructive          = Color(0xFF7F1D1D);
  static const Color destructiveForeground = Color(0xFFF8FAFC);

  // ── Border / Input / Ring ─────────────────────────────────────────────────
  static const Color border               = Color(0xFF1E293B);
  static const Color input                = Color(0xFF1E293B);
  static const Color ring                 = Color(0xFFCBD5E1);
}
