/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/ingredient.dart';
import 'package:gitjournal/core/ingredients/ingredient_parser.dart';
import 'package:gitjournal/core/ingredients/parse_exception.dart';

void main() {
  group('IngredientParser basic parsing', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('parses simple amount + unit + name', () {
      final ingredient = parser.parse('2 cups flour');
      
      expect(ingredient.name, equals('flour'));
      expect(ingredient.amount, equals(2.0));
      expect(ingredient.unit, equals('cups'));
      expect(ingredient.hasConversion, isTrue);
    });

    test('parses mixed fractions', () {
      final ingredient = parser.parse('2 1/2 cups flour');
      
      expect(ingredient.name, equals('flour'));
      expect(ingredient.amount, equals(2.5));
      expect(ingredient.unit, equals('cups'));
    });

    test('parses simple fractions', () {
      final ingredient = parser.parse('1/4 tsp salt');
      
      expect(ingredient.name, equals('salt'));
      expect(ingredient.amount, equals(0.25));
      expect(ingredient.unit, equals('tsp'));
    });

    test('parses metric units', () {
      final ingredient = parser.parse('250 g sugar');
      
      expect(ingredient.name, equals('sugar'));
      expect(ingredient.amount, equals(250.0));
      expect(ingredient.unit, equals('g'));
    });

    test('parses no space between amount and unit', () {
      final ingredient = parser.parse('250g butter');
      
      expect(ingredient.name, equals('butter'));
      expect(ingredient.amount, equals(250.0));
      expect(ingredient.unit, equals('g'));
    });

    test('parses count items without unit', () {
      final ingredient = parser.parse('3 eggs');
      
      expect(ingredient.name, equals('eggs'));
      expect(ingredient.amount, equals(3.0));
      expect(ingredient.unit, equals(''));
    });

    test('parses multi-word ingredient names', () {
      final ingredient = parser.parse('2 cups all-purpose flour');
      
      expect(ingredient.name, equals('all-purpose flour'));
      expect(ingredient.amount, equals(2.0));
      expect(ingredient.unit, equals('cups'));
    });

    test('parses tablespoons', () {
      final ingredient = parser.parse('2 tbsp olive oil');
      
      expect(ingredient.name, equals('olive oil'));
      expect(ingredient.amount, equals(2.0));
      expect(ingredient.unit, equals('tbsp'));
    });

    test('parses teaspoons', () {
      final ingredient = parser.parse('1 tsp vanilla extract');
      
      expect(ingredient.name, equals('vanilla extract'));
      expect(ingredient.amount, equals(1.0));
      expect(ingredient.unit, equals('tsp'));
    });

    test('parses milliliters', () {
      final ingredient = parser.parse('500 ml milk');
      
      expect(ingredient.name, equals('milk'));
      expect(ingredient.amount, equals(500.0));
      expect(ingredient.unit, equals('ml'));
    });

    test('parses ounces', () {
      final ingredient = parser.parse('8 oz chocolate');
      
      expect(ingredient.name, equals('chocolate'));
      expect(ingredient.amount, equals(8.0));
      expect(ingredient.unit, equals('oz'));
    });

    test('parses pounds', () {
      final ingredient = parser.parse('2 lbs potatoes');
      
      expect(ingredient.name, equals('potatoes'));
      expect(ingredient.amount, equals(2.0));
      expect(ingredient.unit, equals('lbs'));
    });

    test('handles whitespace', () {
      final ingredient = parser.parse('  2   cups   flour  ');
      
      expect(ingredient.name, equals('flour'));
      expect(ingredient.amount, equals(2.0));
    });
  });

  group('IngredientParser with milliliter conversion', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('converts cups to ml for known ingredients', () {
      final ingredient = parser.parse('2 cups flour');
      
      expect(ingredient.hasConversion, isTrue);
      expect(ingredient.milliliters, closeTo(416.0, 5.0)); // 2 * 208
    });

    test('converts tbsp to ml', () {
      final ingredient = parser.parse('2 tbsp oil');
      
      expect(ingredient.hasConversion, isTrue);
      expect(ingredient.milliliters, closeTo(30.0, 2.0)); // 2 * 15
    });

    test('converts grams to ml (water density)', () {
      final ingredient = parser.parse('250 g water');
      
      expect(ingredient.hasConversion, isTrue);
      expect(ingredient.milliliters, equals(250.0));
    });

    test('no conversion for count items', () {
      final ingredient = parser.parse('3 eggs');
      
      expect(ingredient.hasConversion, isFalse);
      expect(ingredient.milliliters, isNull);
    });

    test('no conversion for unknown ingredients without weight', () {
      final ingredient = parser.parse('2 cups xyzabc');
      
      // xyzabc has no density, so no conversion
      expect(ingredient.hasConversion, isFalse);
      expect(ingredient.milliliters, isNull);
    });
  });

  group('IngredientParser error cases', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('throws on empty string', () {
      expect(
        () => parser.parse(''),
        throwsA(isA<ParseException>()),
      );
    });

    test('throws on only whitespace', () {
      expect(
        () => parser.parse('   '),
        throwsA(isA<ParseException>()),
      );
    });

    test('throws on missing amount', () {
      expect(
        () => parser.parse('cups flour'),
        throwsA(isA<ParseException>()),
      );
    });

    test('throws on missing name', () {
      expect(
        () => parser.parse('2 cups'),
        throwsA(isA<ParseException>()),
      );
    });

    test('throws on just a number', () {
      expect(
        () => parser.parse('2'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('IngredientParser.tryParse', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('returns ingredient on valid input', () {
      final ingredient = parser.tryParse('2 cups flour');
      
      expect(ingredient, isNotNull);
      expect(ingredient!.name, equals('flour'));
    });

    test('returns null on invalid input', () {
      final ingredient = parser.tryParse('invalid');
      
      expect(ingredient, isNull);
    });

    test('returns null on empty string', () {
      final ingredient = parser.tryParse('');
      
      expect(ingredient, isNull);
    });
  });

  group('Ingredient model', () {
    test('displayText includes ml when available', () {
      final ingredient = Ingredient(
        name: 'flour',
        amount: 2.5,
        unit: 'cups',
        milliliters: 520.0,
      );
      
      expect(ingredient.displayText, contains('cups'));
      expect(ingredient.displayText, contains('flour'));
      expect(ingredient.displayText, contains('520ml'));
    });

    test('displayText without ml when not available', () {
      final ingredient = Ingredient(
        name: 'eggs',
        amount: 3,
        unit: '',
      );
      
      expect(ingredient.displayText, equals('3 eggs'));
    });

    test('shortDisplay never includes ml', () {
      final ingredient = Ingredient(
        name: 'flour',
        amount: 2.5,
        unit: 'cups',
        milliliters: 520.0,
      );
      
      expect(ingredient.shortDisplay, equals('2 1/2 cups flour'));
    });

    test('scales correctly', () {
      final ingredient = Ingredient(
        name: 'flour',
        amount: 2,
        unit: 'cups',
        milliliters: 416.0,
      );
      
      final scaled = ingredient.scale(2.0);
      
      expect(scaled.amount, equals(4.0));
      expect(scaled.milliliters, equals(832.0));
    });

    test('YAML serialization round-trip', () {
      final ingredient = Ingredient(
        name: 'flour',
        amount: 2.5,
        unit: 'cups',
        milliliters: 520.0,
      );
      
      final yaml = ingredient.toYaml();
      final restored = Ingredient.fromYaml(yaml);
      
      expect(restored, equals(ingredient));
    });

    test('YAML without ml', () {
      final ingredient = Ingredient(
        name: 'eggs',
        amount: 3,
        unit: '',
      );
      
      final yaml = ingredient.toYaml();
      expect(yaml.containsKey('ml'), isFalse);
      
      final restored = Ingredient.fromYaml(yaml);
      expect(restored.milliliters, isNull);
    });
  });

  group('Ingredient edge cases', () {
    late IngredientParser parser;

    setUp(() {
      parser = IngredientParser();
    });

    test('handles decimal amounts', () {
      final ingredient = parser.parse('1.5 cups sugar');
      
      expect(ingredient.amount, equals(1.5));
    });

    test('handles large amounts', () {
      final ingredient = parser.parse('1000 g flour');
      
      expect(ingredient.amount, equals(1000.0));
    });

    test('handles very small amounts', () {
      final ingredient = parser.parse('1/8 tsp spice');
      
      expect(ingredient.amount, equals(0.125));
    });

    test('handles ingredient with numbers in name', () {
      final ingredient = parser.parse('2 cloves garlic');
      
      expect(ingredient.name, equals('garlic'));
      expect(ingredient.amount, equals(2.0));
      expect(ingredient.unit, equals('cloves'));
    });

    test('handles hyphenated names', () {
      final ingredient = parser.parse('1 cup half-and-half');
      
      expect(ingredient.name, equals('half-and-half'));
    });
  });
}
