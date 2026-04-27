/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/ingredient_parser.dart';

void main() {
  group('IngredientParser Spanish', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('parses Spanish volume units', () {
      final testCases = [
        ('2 tazas harina', 'harina', 2.0, 'tazas'),
        ('1 cucharada azúcar', 'azúcar', 1.0, 'cucharada'),
        ('3 cucharaditas sal', 'sal', 3.0, 'cucharaditas'),
        ('500 ml leche', 'leche', 500.0, 'ml'),
        ('1 litro agua', 'agua', 1.0, 'litro'),
      ];

      for (final (input, name, amount, unit) in testCases) {
        final result = parser.parse(input);
        expect(result.name, equals(name));
        expect(result.amount, equals(amount));
        expect(result.unit, equals(unit));
      }
    });

    test('parses Spanish weight units', () {
      final testCases = [
        ('250 gramos harina', 'harina', 250.0, 'gramos'),
        ('1 kilo arroz', 'arroz', 1.0, 'kilo'),
        ('500 gr mantequilla', 'mantequilla', 500.0, 'gr'),
      ];

      for (final (input, name, amount, unit) in testCases) {
        final result = parser.parse(input);
        expect(result.name, equals(name));
        expect(result.amount, equals(amount));
        expect(result.unit, equals(unit));
      }
    });

    test('parses Spanish abbreviations', () {
      final testCases = [
        ('2 tz harina', 'harina', 2.0, 'tz'),
        ('1 cda azúcar', 'azúcar', 1.0, 'cda'),
        ('3 cdta sal', 'sal', 3.0, 'cdta'),
      ];

      for (final (input, name, amount, unit) in testCases) {
        final result = parser.parse(input);
        expect(result.name, equals(name));
        expect(result.amount, equals(amount));
        expect(result.unit, equals(unit));
      }
    });

    test('handles Spanish ingredient names with accents', () {
      final result = parser.parse('2 tazas azúcar');
      expect(result.name, equals('azúcar'));
      expect(result.amount, equals(2.0));
      expect(result.unit, equals('tazas'));
    });

    test('tryParse returns null for invalid Spanish input', () {
      expect(parser.tryParse(''), isNull);
      expect(parser.tryParse('harina'), isNull); // No amount
    });
  });
}
