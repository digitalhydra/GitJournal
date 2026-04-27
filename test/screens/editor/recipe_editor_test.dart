/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/ingredient.dart';
import 'package:gitjournal/core/recipe/recipe.dart';

void main() {
  group('Recipe Editor Data', () {
    test('can create recipe with ingredients', () {
      final ingredients = [
        Ingredient(name: 'harina', amount: 250, unit: 'g'),
        Ingredient(name: 'huevos', amount: 3, unit: ''),
        Ingredient(name: 'leche', amount: 200, unit: 'ml'),
      ];

      final recipe = Recipe(
        title: 'Tortilla',
        ingredients: ingredients,
        body: 'Mezclar todo y cocinar',
        tags: ['desayuno', 'rápido'],
        prepTime: 10,
        cookTime: 15,
        servings: 2,
      );

      expect(recipe.title, equals('Tortilla'));
      expect(recipe.ingredients.length, equals(3));
      expect(recipe.ingredients[0].displayText, equals('250 g harina'));
      expect(recipe.tags, contains('desayuno'));
      expect(recipe.prepTime, equals(10));
      expect(recipe.servings, equals(2));
    });

    test('can edit existing recipe', () {
      var recipe = Recipe(
        title: 'Pasta',
        ingredients: [Ingredient(name: 'pasta', amount: 200, unit: 'g')],
        body: 'Hervir pasta',
      );

      // Simulate editing
      recipe = Recipe(
        id: recipe.id,
        title: 'Pasta Carbonara',
        ingredients: [
          Ingredient(name: 'pasta', amount: 200, unit: 'g'),
          Ingredient(name: 'huevo', amount: 2, unit: ''),
        ],
        body: 'Hervir pasta y mezclar con huevo',
        prepTime: 5,
        cookTime: 10,
      );

      expect(recipe.title, equals('Pasta Carbonara'));
      expect(recipe.ingredients.length, equals(2));
      expect(recipe.prepTime, equals(5));
    });

    test('ingredient displays correctly with different units', () {
      final testCases = [
        (Ingredient(name: 'harina', amount: 250, unit: 'g'), '250 g harina'),
        (Ingredient(name: 'leche', amount: 1, unit: 'taza'), '1 taza leche'),
        (Ingredient(name: 'sal', amount: 1, unit: 'cdta'), '1 cdta sal'),
        (Ingredient(name: 'huevos', amount: 3, unit: ''), '3 huevos'),
      ];

      for (final (ingredient, expected) in testCases) {
        expect(ingredient.displayText, equals(expected));
      }
    });
  });
}
