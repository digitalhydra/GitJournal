/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/density_table.dart';
import 'package:gitjournal/core/ingredients/unit_converter.dart';

void main() {
  group('UnitConverter Spanish', () {
    late UnitConverter converter;

    setUp(() {
      converter = UnitConverter();
    });

    test('converts Spanish volume units to ml', () {
      expect(converter.convert(1, 'taza'), equals(236.588));
      expect(converter.convert(1, 'tazas'), equals(236.588));
      expect(converter.convert(1, 'cucharada'), equals(14.7868));
      expect(converter.convert(1, 'cucharadita'), equals(4.92892));
      expect(converter.convert(1, 'litro'), equals(1000.0));
      expect(converter.convert(1, 'mililitro'), equals(1.0));
    });

    test('converts Spanish weight units to ml', () {
      expect(converter.convert(1, 'gramo'), equals(1.0));
      expect(converter.convert(1, 'kilogramo'), equals(1000.0));
      expect(converter.convert(1, 'onza'), equals(28.3495));
      expect(converter.convert(1, 'libra'), equals(453.592));
    });

    test('converts Spanish abbreviations', () {
      expect(converter.convert(1, 'cda'), equals(14.7868));
      expect(converter.convert(1, 'cdta'), equals(4.92892));
      expect(converter.convert(1, 'tz'), equals(236.588));
    });
  });

  group('DensityTable Spanish', () {
    test('has densities for Spanish ingredients', () {
      final table = DensityTable();

      // Test Spanish ingredient names
      expect(table.hasDensity('harina'), isTrue);
      expect(table.hasDensity('azúcar'), isTrue);
      expect(table.hasDensity('mantequilla'), isTrue);
      expect(table.hasDensity('leche'), isTrue);
      expect(table.hasDensity('sal'), isTrue);
      expect(table.hasDensity('arroz'), isTrue);
      expect(table.hasDensity('avena'), isTrue);
    });

    test('normalizes Spanish ingredient names with accents', () {
      final table = DensityTable();

      // These should all find the same density
      expect(table.getDensity('azúcar'), equals(250.0));
      expect(table.getDensity('azucar'), equals(250.0));
      expect(table.getDensity('azúcar blanca'), equals(250.0));
    });

    test('returns correct densities for Spanish ingredients', () {
      final table = DensityTable();

      expect(table.getDensity('harina'), equals(208.0));
      expect(table.getDensity('azúcar'), equals(250.0));
      expect(table.getDensity('mantequilla'), equals(237.0));
      expect(table.getDensity('leche'), equals(244.0));
      expect(table.getDensity('sal'), equals(273.0));
      expect(table.getDensity('arroz'), equals(231.0));
    });
  });
}
