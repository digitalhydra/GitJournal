/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/// Formats decimal numbers as human-readable fractions
/// 2.5 → "2 1/2"
/// 0.333 → "1/3"
/// 2.0 → "2"
class DecimalFormatter {
  static final Map<double, String> _commonFractions = {
    0.5: '1/2',
    0.25: '1/4',
    0.75: '3/4',
    0.333: '1/3',
    0.667: '2/3',
    0.125: '1/8',
    0.375: '3/8',
    0.625: '5/8',
    0.875: '7/8',
    0.2: '1/5',
    0.4: '2/5',
    0.6: '3/5',
    0.8: '4/5',
    0.167: '1/6',
    0.833: '5/6',
  };

  /// Formats a decimal as a fraction string
  static String format(double value, {double tolerance = 0.01}) {
    if (value.isInfinite || value.isNaN) {
      return value.toString();
    }

    // Handle zero
    if (value == 0) {
      return '0';
    }

    // Handle negative
    final negative = value < 0;
    value = value.abs();

    // Extract whole number and decimal parts
    final whole = value.floor();
    final decimal = value - whole;

    // If no decimal part, return whole number
    if (decimal < 0.001) {
      return negative ? '-$whole' : '$whole';
    }

    // Try to match common fraction
    String? fractionStr;
    for (final entry in _commonFractions.entries) {
      if ((decimal - entry.key).abs() < tolerance) {
        fractionStr = entry.value;
        break;
      }
    }

    // If no common match, compute fraction
    fractionStr ??= _computeFraction(decimal, tolerance: tolerance);

    // Build result
    final result = whole > 0 ? '$whole $fractionStr' : fractionStr;
    return negative ? '-$result' : result;
  }

  /// Computes a fraction representation using continued fractions
  static String _computeFraction(double decimal, {double tolerance = 0.01}) {
    if (decimal < 0.001) return '0';

    int maxDenominator = 16; // Don't go beyond /16
    double bestNumerator = 1;
    double bestDenominator = 1;
    double bestError = (decimal - bestNumerator / bestDenominator).abs();

    for (int d = 2; d <= maxDenominator; d++) {
      final n = (decimal * d).round();
      if (n == 0) continue;

      final error = (decimal - n / d).abs();
      if (error < bestError) {
        bestError = error;
        bestNumerator = n.toDouble();
        bestDenominator = d.toDouble();
      }
    }

    // Simplify
    final gcd = _gcd(bestNumerator.toInt(), bestDenominator.toInt());
    final simplifiedNum = (bestNumerator / gcd).toInt();
    final simplifiedDen = (bestDenominator / gcd).toInt();

    return '$simplifiedNum/$simplifiedDen';
  }

  static int _gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// Parses a fraction string back to decimal
  /// "2 1/2" → 2.5
  /// "3/4" → 0.75
  /// "5" → 5.0
  static double? parse(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    // Try parsing as plain number first
    final plain = double.tryParse(input);
    if (plain != null) return plain;

    // Try "2 1/2" format
    final mixedMatch = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(input);
    if (mixedMatch != null) {
      final whole = int.parse(mixedMatch.group(1)!);
      final num = int.parse(mixedMatch.group(2)!);
      final den = int.parse(mixedMatch.group(3)!);
      if (den == 0) return null;
      return whole + (num / den);
    }

    // Try "1/2" format
    final fractionMatch = RegExp(r'^(\d+)/(\d+)$').firstMatch(input);
    if (fractionMatch != null) {
      final num = int.parse(fractionMatch.group(1)!);
      final den = int.parse(fractionMatch.group(2)!);
      if (den == 0) return null;
      return num / den;
    }

    return null;
  }
}
