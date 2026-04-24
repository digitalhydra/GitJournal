/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/density_table.dart';

void main() {
  group('DensityTable defaults', () {
    late DensityTable table;

    setUp(() {
      table = DensityTable();
    });

    test('has flour density', () {
      expect(table.getDensity('flour'), equals(208.0));
      expect(table.getDensity('all-purpose flour'), equals(208.0));
      expect(table.getDensity('All Purpose Flour'), equals(208.0));
    });

    test('has sugar densities', () {
      expect(table.getDensity('sugar'), equals(250.0));
      expect(table.getDensity('granulated sugar'), equals(250.0));
      expect(table.getDensity('brown sugar'), equals(275.0));
      expect(table.getDensity('powdered sugar'), equals(200.0));
    });

    test('has butter density', () {
      expect(table.getDensity('butter'), equals(237.0));
    });

    test('has oil density', () {
      expect(table.getDensity('oil'), equals(250.0));
      expect(table.getDensity('olive oil'), equals(250.0));
      expect(table.getDensity('vegetable oil'), equals(250.0));
    });

    test('has rice density', () {
      expect(table.getDensity('rice'), equals(231.0));
      expect(table.getDensity('white rice'), equals(231.0));
    });

    test('returns null for unknown ingredient', () {
      expect(table.getDensity('xyz'), isNull);
      expect(table.getDensity('unknown ingredient'), isNull);
    });

    test('hasDensity returns correct values', () {
      expect(table.hasDensity('flour'), isTrue);
      expect(table.hasDensity('xyz'), isFalse);
    });

    test('returns 20+ default ingredients', () {
      expect(table.defaults.length, greaterThanOrEqualTo(20));
    });
  });

  group('DensityTable user overrides', () {
    late DensityTable table;

    setUp(() {
      table = DensityTable();
    });

    test('can add user override', () {
      table.setDensity('custom_flour', 200.0);
      expect(table.getDensity('custom_flour'), equals(200.0));
    });

    test('user override takes precedence over default', () {
      // Default flour is 208
      expect(table.getDensity('flour'), equals(208.0));
      
      // Override it
      table.setDensity('flour', 220.0);
      expect(table.getDensity('flour'), equals(220.0));
      
      // But defaults remain unchanged
      expect(table.defaults['flour'], equals(208.0));
    });

    test('can remove user override', () {
      table.setDensity('flour', 220.0);
      expect(table.getDensity('flour'), equals(220.0));
      
      table.removeDensity('flour');
      expect(table.getDensity('flour'), equals(208.0)); // Back to default
    });

    test('lists all ingredients', () {
      final ingredients = table.listIngredients();
      expect(ingredients.contains('flour'), isTrue);
      expect(ingredients.contains('sugar'), isTrue);
      expect(ingredients.contains('butter'), isTrue);
    });
  });

  group('DensityTable JSON persistence', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('density_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saves and loads user overrides', () async {
      // Create table with overrides
      final table = DensityTable(repoPath: tempDir.path);
      table.setDensity('custom_item', 300.0);
      table.setDensity('another_item', 150.0);

      // Save
      await table.saveToRepo();

      // Load new table from same path
      final loadedTable = await DensityTable.loadFromRepo(tempDir.path);

      // Verify overrides loaded
      expect(loadedTable.getDensity('custom_item'), equals(300.0));
      expect(loadedTable.getDensity('another_item'), equals(150.0));
      
      // Verify defaults still work
      expect(loadedTable.getDensity('flour'), equals(208.0));
    });

    test('creates .recipejournal directory', () async {
      final table = DensityTable(repoPath: tempDir.path);
      table.setDensity('test', 100.0);
      
      await table.saveToRepo();

      final dir = Directory('${tempDir.path}/.recipejournal');
      expect(await dir.exists(), isTrue);
    });

    test('handles missing file gracefully', () async {
      final table = await DensityTable.loadFromRepo(tempDir.path);
      
      // Should have no overrides but defaults work
      expect(table.userOverrides.isEmpty, isTrue);
      expect(table.getDensity('flour'), equals(208.0));
    });

    test('throws if no repo path on save', () async {
      final table = DensityTable();
      table.setDensity('test', 100.0);
      
      expect(() => table.saveToRepo(), throwsA(isA<StateError>()));
    });
  });

  group('DensityTable name normalization', () {
    test('normalizes various formats', () {
      final table = DensityTable();
      
      // All these should find the same density
      expect(table.getDensity('All-Purpose Flour'), equals(208.0));
      expect(table.getDensity('all purpose flour'), equals(208.0));
      expect(table.getDensity('ALL_PURPOSE_FLOUR'), equals(208.0));
      expect(table.getDensity('all-purpose flour'), equals(208.0));
    });
  });
}
