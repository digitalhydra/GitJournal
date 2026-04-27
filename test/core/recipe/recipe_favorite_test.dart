/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/ingredient.dart';
import 'package:gitjournal/core/recipe/recipe.dart';
import 'package:gitjournal/core/recipe/recipe_serializer.dart';

void main() {
  group('Recipe Favorite', () {
    test('recipe is not favorite by default', () {
      final recipe = Recipe(
        title: 'Simple Recipe',
        ingredients: [],
      );

      expect(recipe.isFavorite, isFalse);
    });

    test('recipe can be created as favorite', () {
      final recipe = Recipe(
        title: 'Favorite Recipe',
        ingredients: [],
        isFavorite: true,
      );

      expect(recipe.isFavorite, isTrue);
    });

    test('favorite status is serialized to YAML', () {
      final recipe = Recipe(
        title: 'Favorite Recipe',
        ingredients: [Ingredient(name: 'sugar', amount: 100, unit: 'g')],
        isFavorite: true,
      );

      final yaml = RecipeSerializer.encode(recipe);
      expect(yaml.contains('favorite: true'), isTrue);
    });

    test('favorite status is not serialized when false', () {
      final recipe = Recipe(
        title: 'Regular Recipe',
        ingredients: [],
        isFavorite: false,
      );

      final yaml = RecipeSerializer.encode(recipe);
      expect(yaml.contains('favorite:'), isFalse);
    });

    test('favorite status is deserialized from YAML', () {
      const markdown = '''---
id: "test-id"
title: "Favorite Recipe"
favorite: true
ingredients:
  - name: "flour"
    amount: 200
    unit: "g"
---

Instructions here.
'''
      ;

      final recipe = RecipeSerializer.decode(markdown);
      expect(recipe.isFavorite, isTrue);
    });

    test('recipe without favorite field defaults to false', () {
      const markdown = '''---
id: "test-id"
title: "Regular Recipe"
ingredients: []
---

Instructions.
'''
      ;

      final recipe = RecipeSerializer.decode(markdown);
      expect(recipe.isFavorite, isFalse);
    });

    test('can toggle favorite with copyWith', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
        isFavorite: false,
      );

      final favoriteRecipe = recipe.copyWith(isFavorite: true);
      expect(favoriteRecipe.isFavorite, isTrue);
      expect(recipe.isFavorite, isFalse); // Original unchanged
    });
  });
}
