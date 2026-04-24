/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/utils/decimal_formatter.dart';

void main() {
  group('DecimalFormatter.format', () {
    test('formats whole numbers', () {
      expect(DecimalFormatter.format(2.0), equals('2'));
      expect(DecimalFormatter.format(5.0), equals('5'));
      expect(DecimalFormatter.format(0.0), equals('0'));
    });

    test('formats common fractions', () {
      expect(DecimalFormatter.format(0.5), equals('1/2'));
      expect(DecimalFormatter.format(0.25), equals('1/4'));
      expect(DecimalFormatter.format(0.75), equals('3/4'));
      expect(DecimalFormatter.format(0.333), equals('1/3'));
      expect(DecimalFormatter.format(0.667), equals('2/3'));
    });

    test('formats mixed numbers', () {
      expect(DecimalFormatter.format(2.5), equals('2 1/2'));
      expect(DecimalFormatter.format(1.5), equals('1 1/2'));
      expect(DecimalFormatter.format(3.25), equals('3 1/4'));
      expect(DecimalFormatter.format(2.75), equals('2 3/4'));
    });

    test('formats approximate fractions', () {
      // 0.4 is 2/5
      expect(DecimalFormatter.format(0.4), equals('2/5'));
      // 0.6 is 3/5
      expect(DecimalFormatter.format(0.6), equals('3/5'));
    });

    test('handles negative numbers', () {
      expect(DecimalFormatter.format(-0.5), equals('-1/2'));
      expect(DecimalFormatter.format(-2.5), equals('-2 1/2'));
      expect(DecimalFormatter.format(-3.0), equals('-3'));
    });

    test('handles special values', () {
      expect(DecimalFormatter.format(double.infinity), equals('Infinity'));
      expect(DecimalFormatter.format(double.nan), equals('NaN'));
    });
  });

  group('DecimalFormatter.parse', () {
    test('parses whole numbers', () {
      expect(DecimalFormatter.parse('2'), equals(2.0));
      expect(DecimalFormatter.parse('5'), equals(5.0));
      expect(DecimalFormatter.parse('0'), equals(0.0));
    });

    test('parses fractions', () {
      expect(DecimalFormatter.parse('1/2'), equals(0.5));
      expect(DecimalFormatter.parse('3/4'), equals(0.75));
      expect(DecimalFormatter.parse('2/3'), equals(0.6666666666666666));
    });

    test('parses mixed numbers', () {
      expect(DecimalFormatter.parse('2 1/2'), equals(2.5));
      expect(DecimalFormatter.parse('1 3/4'), equals(1.75));
      expect(DecimalFormatter.parse('3 1/3'), equals(3.3333333333333335));
    });

    test('parses decimals', () {
      expect(DecimalFormatter.parse('2.5'), equals(2.5));
      expect(DecimalFormatter.parse('0.75'), equals(0.75));
    });

    test('handles whitespace', () {
      expect(DecimalFormatter.parse('  2 1/2  '), equals(2.5));
      expect(DecimalFormatter.parse('  3/4 '), equals(0.75));
    });

    test('returns null for invalid input', () {
      expect(DecimalFormatter.parse(''), isNull);
      expect(DecimalFormatter.parse('abc'), isNull);
      expect(DecimalFormatter.parse('1/0'), isNull); // Division by zero
    });
  });

  group('Round-trip conversion', () {
    test('format then parse preserves value', () {
      const testValues = [0.5, 0.25, 0.75, 2.5, 1.333, 3.0];
      
      for (final value in testValues) {
        final formatted = DecimalFormatter.format(value);
        final parsed = DecimalFormatter.parse(formatted);
        
        // Allow small tolerance for fraction approximations
        expect(
          (parsed! - value).abs() < 0.01,
          isTrue,
          reason: 'Value $value formatted as "$formatted" parsed back to $parsed',
        );
      }
    });
  });
}
