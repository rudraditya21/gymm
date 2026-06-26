import 'package:flutter/material.dart';

// Converted from oklch() via the OKLab → linear-sRGB → gamma pipeline.
// Source: the shadcn globals.css (tailwind v4, oklch palette).

/// Shadcn light-theme color tokens  (:root)
abstract final class AppLightColors {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const Color background           = Color(0xFFFFFFFF); // oklch(1 0 0)
  static const Color foreground           = Color(0xFF0A0A0A); // oklch(0.145 0 0)

  // ── Card ──────────────────────────────────────────────────────────────────
  static const Color card                 = Color(0xFFFFFFFF); // oklch(1 0 0)
  static const Color cardForeground       = Color(0xFF0A0A0A); // oklch(0.145 0 0)

  // ── Popover ───────────────────────────────────────────────────────────────
  static const Color popover              = Color(0xFFFFFFFF); // oklch(1 0 0)
  static const Color popoverForeground    = Color(0xFF0A0A0A); // oklch(0.145 0 0)

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary              = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color primaryForeground    = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary            = Color(0xFFF5F5F5); // oklch(0.97 0 0)
  static const Color secondaryForeground  = Color(0xFF171717); // oklch(0.205 0 0)

  // ── Muted ─────────────────────────────────────────────────────────────────
  static const Color muted                = Color(0xFFF5F5F5); // oklch(0.97 0 0)
  static const Color mutedForeground      = Color(0xFF737373); // oklch(0.556 0 0)

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent               = Color(0xFFF5F5F5); // oklch(0.97 0 0)
  static const Color accentForeground     = Color(0xFF171717); // oklch(0.205 0 0)

  // ── Destructive ───────────────────────────────────────────────────────────
  static const Color destructive          = Color(0xFFE7000B); // oklch(0.577 0.245 27.325)

  // ── Border / Input / Ring ─────────────────────────────────────────────────
  static const Color border               = Color(0xFFE5E5E5); // oklch(0.922 0 0)
  static const Color input                = Color(0xFFE5E5E5); // oklch(0.922 0 0)
  static const Color ring                 = Color(0xFFA1A1A1); // oklch(0.708 0 0)

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const Color chart1               = Color(0xFFF54900); // oklch(0.646 0.222 41.116)
  static const Color chart2               = Color(0xFF009689); // oklch(0.6 0.118 184.704)
  static const Color chart3               = Color(0xFF104E64); // oklch(0.398 0.07 227.392)
  static const Color chart4               = Color(0xFFFFB900); // oklch(0.828 0.189 84.429)
  static const Color chart5               = Color(0xFFFE9A00); // oklch(0.769 0.188 70.08)

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const Color sidebar              = Color(0xFFFAFAFA); // oklch(0.985 0 0)
  static const Color sidebarForeground    = Color(0xFF0A0A0A); // oklch(0.145 0 0)
  static const Color sidebarPrimary       = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color sidebarPrimaryForeground = Color(0xFFFAFAFA); // oklch(0.985 0 0)
  static const Color sidebarAccent        = Color(0xFFF5F5F5); // oklch(0.97 0 0)
  static const Color sidebarAccentForeground  = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color sidebarBorder        = Color(0xFFE5E5E5); // oklch(0.922 0 0)
  static const Color sidebarRing          = Color(0xFFA1A1A1); // oklch(0.708 0 0)
}

/// Shadcn dark-theme color tokens  (.dark)
abstract final class AppDarkColors {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const Color background           = Color(0xFF0A0A0A); // oklch(0.145 0 0)
  static const Color foreground           = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Card ──────────────────────────────────────────────────────────────────
  static const Color card                 = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color cardForeground       = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Popover ───────────────────────────────────────────────────────────────
  static const Color popover              = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color popoverForeground    = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary              = Color(0xFFE5E5E5); // oklch(0.922 0 0)
  static const Color primaryForeground    = Color(0xFF171717); // oklch(0.205 0 0)

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary            = Color(0xFF262626); // oklch(0.269 0 0)
  static const Color secondaryForeground  = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Muted ─────────────────────────────────────────────────────────────────
  static const Color muted                = Color(0xFF262626); // oklch(0.269 0 0)
  static const Color mutedForeground      = Color(0xFFA1A1A1); // oklch(0.708 0 0)

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent               = Color(0xFF262626); // oklch(0.269 0 0)
  static const Color accentForeground     = Color(0xFFFAFAFA); // oklch(0.985 0 0)

  // ── Destructive ───────────────────────────────────────────────────────────
  static const Color destructive          = Color(0xFFFF6467); // oklch(0.704 0.191 22.216)

  // ── Border / Input / Ring ─────────────────────────────────────────────────
  // oklch(1 0 0 / 10%) and oklch(1 0 0 / 15%) — white with alpha
  static const Color border               = Color(0x1AFFFFFF); // oklch(1 0 0 / 10%)
  static const Color input                = Color(0x26FFFFFF); // oklch(1 0 0 / 15%)
  static const Color ring                 = Color(0xFF737373); // oklch(0.556 0 0)

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const Color chart1               = Color(0xFF1447E6); // oklch(0.488 0.243 264.376)
  static const Color chart2               = Color(0xFF00BC7D); // oklch(0.696 0.17 162.48)
  static const Color chart3               = Color(0xFFFE9A00); // oklch(0.769 0.188 70.08)
  static const Color chart4               = Color(0xFFAD46FF); // oklch(0.627 0.265 303.9)
  static const Color chart5               = Color(0xFFFF2056); // oklch(0.645 0.246 16.439)

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const Color sidebar              = Color(0xFF171717); // oklch(0.205 0 0)
  static const Color sidebarForeground    = Color(0xFFFAFAFA); // oklch(0.985 0 0)
  static const Color sidebarPrimary       = Color(0xFF1447E6); // oklch(0.488 0.243 264.376)
  static const Color sidebarPrimaryForeground = Color(0xFFFAFAFA); // oklch(0.985 0 0)
  static const Color sidebarAccent        = Color(0xFF262626); // oklch(0.269 0 0)
  static const Color sidebarAccentForeground  = Color(0xFFFAFAFA); // oklch(0.985 0 0)
  static const Color sidebarBorder        = Color(0x1AFFFFFF); // oklch(1 0 0 / 10%)
  static const Color sidebarRing          = Color(0xFF737373); // oklch(0.556 0 0)
}
