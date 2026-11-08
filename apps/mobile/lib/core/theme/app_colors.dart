import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand colors (source of truth — never use hex values outside this file) ──

  /// Forest Green — primary brand color
  static const Color primaryGreen = Color(0xFF1F3D2B);

  /// Sand Beige — secondary brand color
  static const Color sandBeige = Color(0xFFE8DCC4);

  // ── Derived neutrals ──────────────────────────────────────────────────────

  /// Page background — Sand Beige lightened ~6 per channel toward white (#F6F0E2)
  static const Color pageBackground = Color(0xFFF6F0E2);

  /// Body text — Forest Green scaled to ~84% brightness; green-tinted near-black (#1A2A1F)
  static const Color bodyText = Color(0xFF1A2A1F);

  /// Secondary text / labels — Forest Green mixed 50% with mid-gray; muted green-gray (#4E6855)
  /// Contrast on pageBackground: ≥4.84:1 (passes WCAG AA)
  static const Color secondaryText = Color(0xFF4E6855);

  /// Divider — Sand Beige darkened slightly; decorative only, no contrast requirement
  static const Color divider = Color(0xFFD0C5A8);

  /// Surface — same as sandBeige; used for cards and secondary button backgrounds
  static const Color surface = Color(0xFFE8DCC4);

  /// Pure white — used for app bar text/icons and primary button labels
  static const Color white = Color(0xFFFFFFFF);

  // ── Listing-check badge colors ─────────────────────────────────────────────
  // Intentionally distinct from brand green so badges are not confused with active states.
  // All fg/bg pairs pass WCAG AA (≥4.5:1). Each badge also uses icon + text, never color alone.

  /// LOW risk badge background — light teal
  static const Color riskLowBg = Color(0xFFDCF5F0);

  /// LOW risk badge foreground — dark teal; contrast on riskLowBg: ≥5.5:1
  static const Color riskLowFg = Color(0xFF0A6655);

  /// MEDIUM risk badge background — light amber
  static const Color riskMediumBg = Color(0xFFFEF3C7);

  /// MEDIUM risk badge foreground — dark amber; contrast on riskMediumBg: ≥5.8:1
  static const Color riskMediumFg = Color(0xFF92400E);

  /// HIGH risk badge background — light red
  static const Color riskHighBg = Color(0xFFFEE2E2);

  /// HIGH risk badge foreground — dark red; contrast on riskHighBg: ≥6.4:1
  static const Color riskHighFg = Color(0xFF991B1B);
}
