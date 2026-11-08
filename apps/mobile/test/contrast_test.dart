import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komerca/core/theme/app_colors.dart';

// WCAG 2.1 relative luminance and contrast ratio helpers.
// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance

double _linearize(double c) {
  if (c <= 0.04045) return c / 12.92;
  return pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  // color.r/g/b return sRGB values in [0.0, 1.0] (Flutter 3.27+)
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color bg, Color fg) {
  final bgL = _luminance(bg);
  final fgL = _luminance(fg);
  final lighter = max(bgL, fgL);
  final darker = min(bgL, fgL);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // WCAG AA requires ≥4.5:1 for normal text.
  const minContrast = 4.5;

  group('WCAG AA contrast — brand color pairs', () {
    test('Primary button: sand text on green bg', () {
      final ratio = contrastRatio(AppColors.primaryGreen, AppColors.sandBeige);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Sand on green: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('Secondary button: green text on sand bg', () {
      final ratio = contrastRatio(AppColors.sandBeige, AppColors.primaryGreen);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Green on sand: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('App bar: white text on green bg', () {
      final ratio = contrastRatio(AppColors.primaryGreen, AppColors.white);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'White on green: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('Body text on page background', () {
      final ratio = contrastRatio(AppColors.pageBackground, AppColors.bodyText);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Body text on page bg: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('Secondary text on page background', () {
      final ratio = contrastRatio(AppColors.pageBackground, AppColors.secondaryText);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Secondary text on page bg: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });
  });

  group('WCAG AA contrast — listing-check badge pairs', () {
    test('LOW risk: fg on bg', () {
      final ratio = contrastRatio(AppColors.riskLowBg, AppColors.riskLowFg);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Low risk: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('MEDIUM risk: fg on bg', () {
      final ratio = contrastRatio(AppColors.riskMediumBg, AppColors.riskMediumFg);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'Medium risk: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });

    test('HIGH risk: fg on bg', () {
      final ratio = contrastRatio(AppColors.riskHighBg, AppColors.riskHighFg);
      expect(
        ratio,
        greaterThanOrEqualTo(minContrast),
        reason: 'High risk: ${ratio.toStringAsFixed(2)}:1 (need $minContrast:1)',
      );
    });
  });
}
