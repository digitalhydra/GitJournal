/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/recipe/recipe.dart';

void main() {
  group('Recipe Image', () {
    test('recipe can have image path', () {
      final recipe = Recipe(
        title: 'Pasta Carbonara',
        ingredients: [],
        imagePath: 'images/recipe_123456.webp',
      );

      expect(recipe.hasImage, isTrue);
      expect(recipe.imagePath, equals('images/recipe_123456.webp'));
    });

    test('recipe without image has null imagePath', () {
      final recipe = Recipe(
        title: 'Simple Recipe',
        ingredients: [],
      );

      expect(recipe.hasImage, isFalse);
      expect(recipe.imagePath, isNull);
    });

    test('recipe can be created without image', () {
      final recipe = Recipe(
        title: 'No Image Recipe',
        ingredients: [],
        body: 'Test instructions',
      );

      expect(recipe.imagePath, isNull);
      expect(recipe.hasImage, isFalse);
    });

    test('recipe can have image added later', () {
      var recipe = Recipe(
        title: 'Recipe Without Image',
        ingredients: [],
      );

      expect(recipe.hasImage, isFalse);

      // Simulate adding image by creating new instance
      recipe = Recipe(
        id: recipe.id,
        title: recipe.title,
        ingredients: recipe.ingredients,
        body: recipe.body,
        imagePath: 'images/new_image.webp',
      );

      expect(recipe.hasImage, isTrue);
      expect(recipe.imagePath, equals('images/new_image.webp'));
    });
  });
}
