/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/density_table.dart';
import 'package:gitjournal/core/ingredients/unit_converter.dart';

void main() {
  group('UnitConverter liquids', () {
    late UnitConverter converter;

    setUp(() {
      converter = UnitConverter();
    });

    test('converts teaspoons to ml', () {
      final result = converter.convert(1, 'tsp');
      expect(result, closeTo(4.93, 0.1));
    });

    test('converts tablespoons to ml', () {
      final result = converter.convert(1, 'tbsp');
      expect(result, closeTo(14.79, 0.1));
    });

    test('converts cups to ml', () {
      final result = converter.convert(1, 'cup');
      expect(result, closeTo(236.59, 0.1));
    });

    test('converts multiple units', () {
      expect(converter.convert(2, 'cups'), closeTo(473.18, 0.1));
      expect(converter.convert(3, 'tbsp'), closeTo(44.36, 0.1));
    });

    test('converts metric units', () {
      expect(converter.convert(250, 'ml'), equals(250.0));
      expect(converter.convert(1, 'liter'), equals(1000.0));
      expect(converter.convert(1, 'l'), equals(1000.0));
    });

    test('converts pints and quarts', () {
      expect(converter.convert(1, 'pt'), closeTo(473.18, 0.1));
      expect(converter.convert(1, 'qt'), closeTo(946.35, 0.1));
    });

    test('handles various unit spellings', () {
      expect(converter.convert(1, 'teaspoon'), isNotNull);
      expect(converter.convert(1, 'teaspoons'), isNotNull);
      expect(converter.convert(1, 'tablespoon'), isNotNull);
      expect(converter.convert(1, 'cups'), isNotNull);
      expect(converter.convert(1, 'C'), isNotNull);
    });
  });

  group('UnitConverter weights', () {
    late UnitConverter converter;

    setUp(() {
      converter = UnitConverter();
    });

    test('converts grams to ml (water approximation)', () {
      expect(converter.convert(100, 'g'), equals(100.0));
      expect(converter.convert(250, 'grams'), equals(250.0));
    });

    test('converts ounces to ml', () {
      expect(converter.convert(1, 'oz'), closeTo(28.35, 0.1));
    });

    test('converts pounds to ml', () {
      expect(converter.convert(1, 'lb'), closeTo(453.59, 0.1));
    });

    test('converts kilograms to ml', () {
      expect(converter.convert(1, 'kg'), equals(1000.0));
    });
  });

  group('UnitConverter with density', () {
    late DensityTable densityTable;
    late UnitConverter converter;

    setUp(() {
      densityTable = DensityTable();
      converter = UnitConverter(densityTable: densityTable);
    });

    test('converts cups of flour using density', () {
      // Flour: 208 ml per cup
      final result = converter.convert(1, 'cup', ingredient: 'flour');
      expect(result, closeTo(208.0, 1.0));
    });

    test('converts cups of sugar using density', () {
      // Sugar: 250 ml per cup
      final result = converter.convert(1, 'cup', ingredient: 'sugar');
      expect(result, closeTo(250.0, 1.0));
    });

    test('converts tablespoons of butter', () {
      // Butter: 237 ml per cup, so 1 tbsp = 237/16 = ~14.8ml
      final result = converter.convert(1, 'tbsp', ingredient: 'butter');
      expect(result, closeTo(14.8, 0.5));
    });

    test('returns null for unknown ingredient', () {
      // Can't convert dry good without density
      final result = converter.convert(1, 'cup', ingredient: 'xyz');
      expect(result, isNull);
    });

    test('uses density when available for liquids', () {
      // Oil has density but is also a liquid unit
      // When density is available, use it for more accurate conversion
      final result = converter.convert(1, 'cup', ingredient: 'oil');
      // Should use density (250) when available
      expect(result, closeTo(250.0, 1.0));
    });
  });

  group('UnitConverter unit detection', () {
    late UnitConverter converter;

    setUp(() {
      converter = UnitConverter();
    });

    test('detects liquid units', () {
      expect(converter.isLiquidUnit('cup'), isTrue);
      expect(converter.isLiquidUnit('tbsp'), isTrue);
      expect(converter.isLiquidUnit('ml'), isTrue);
      expect(converter.isLiquidUnit('g'), isTrue); // Weight counts as liquid for conversion
    });

    test('detects unknown units', () {
      expect(converter.isLiquidUnit('xyz'), isFalse);
      expect(converter.isLiquidUnit('handful'), isFalse);
    });

    test('can check if dry good convertible', () {
      final densityTable = DensityTable();
      final converter = UnitConverter(densityTable: densityTable);
      
      expect(converter.canConvertDryGood('flour'), isTrue);
      expect(converter.canConvertDryGood('sugar'), isTrue);
      expect(converter.canConvertDryGood('xyz'), isFalse);
    });
  });

  group('UnitConverter supported units', () {
    test('lists supported units', () {
      final units = UnitConverter.supportedUnits;
      expect(units.contains('cup'), isTrue);
      expect(units.contains('tbsp'), isTrue);
      expect(units.contains('tsp'), isTrue);
      expect(units.contains('ml'), isTrue);
      expect(units.contains('g'), isTrue);
    });

    test('lists liquid units', () {
      final units = UnitConverter.liquidUnits;
      expect(units.contains('cup'), isTrue);
      expect(units.contains('liter'), isTrue);
    });

    test('lists weight units', () {
      final units = UnitConverter.weightUnits;
      expect(units.contains('g'), isTrue);
      expect(units.contains('oz'), isTrue);
      expect(units.contains('lb'), isTrue);
    });
  });

  group('UnitConverter formatting', () {
    test('formats ml without original unit', () {
      final formatted = UnitConverter.formatWithUnit(250);
      expect(formatted, equals('250ml'));
    });

    test('formats ml with original unit', () {
      final formatted = UnitConverter.formatWithUnit(250, originalUnit: 'cup');
      expect(formatted, contains('250ml'));
      expect(formatted, contains('cup'));
    });

    test('formats whole numbers without decimal', () {
      final formatted = UnitConverter.formatWithUnit(500);
      expect(formatted, startsWith('500ml'));
    });
  });

  group('UnitConverter edge cases', () {
    late UnitConverter converter;

    setUp(() {
      converter = UnitConverter();
    });

    test('handles zero amount', () {
      expect(converter.convert(0, 'cup'), equals(0.0));
    });

    test('handles case insensitive units', () {
      expect(converter.convert(1, 'CUP'), equals(236.588));
      expect(converter.convert(1, 'Cup'), equals(236.588));
      expect(converter.convert(1, 'cUp'), equals(236.588));
    });

    test('handles units with periods removed', () {
      expect(converter.convert(1, 'tsp.'), closeTo(4.93, 0.1));
    });
  });
}
