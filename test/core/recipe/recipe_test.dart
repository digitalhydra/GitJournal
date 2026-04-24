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
  group('Recipe model', () {
    test('creates recipe with default values', () {
      final recipe = Recipe(
        title: 'Test Recipe',
        ingredients: [],
      );
      
      expect(recipe.title, equals('Test Recipe'));
      expect(recipe.id, isNotEmpty);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.body, equals(''));
      expect(recipe.tags, isEmpty);
    });

    test('creates recipe with all fields', () {
      final recipe = Recipe(
        title: 'Carbonara',
        body: '# Instructions\n\nCook pasta',
        ingredients: [
          Ingredient(name: 'pasta', amount: 400, unit: 'g', milliliters: 400),
          Ingredient(name: 'eggs', amount: 3, unit: ''),
        ],
        tags: ['italian', 'pasta'],
        prepTime: 15,
        cookTime: 20,
        servings: 4,
        difficulty: 'medium',
        imagePath: './media/image.webp',
      );
      
      expect(recipe.title, equals('Carbonara'));
      expect(recipe.ingredients.length, equals(2));
      expect(recipe.tags, equals(['italian', 'pasta']));
      expect(recipe.prepTime, equals(15));
      expect(recipe.cookTime, equals(20));
      expect(recipe.servings, equals(4));
      expect(recipe.difficulty, equals('medium'));
      expect(recipe.imagePath, equals('./media/image.webp'));
    });

    test('generates UUID if not provided', () {
      final recipe1 = Recipe(title: 'Recipe 1', ingredients: []);
      final recipe2 = Recipe(title: 'Recipe 2', ingredients: []);
      
      expect(recipe1.id, isNotEmpty);
      expect(recipe2.id, isNotEmpty);
      expect(recipe1.id, isNot(equals(recipe2.id)));
    });

    test('preserves provided UUID', () {
      final recipe = Recipe(
        id: 'custom-id-123',
        title: 'Recipe',
        ingredients: [],
      );
      
      expect(recipe.id, equals('custom-id-123'));
    });

    test('calculates total time', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
        prepTime: 15,
        cookTime: 30,
      );
      
      expect(recipe.totalTime, equals(45));
    });

    test('total time is null when no times set', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
      );
      
      expect(recipe.totalTime, isNull);
    });

    test('hasTime returns false when no times', () {
      final recipe = Recipe(title: 'Recipe', ingredients: []);
      expect(recipe.hasTime, isFalse);
    });

    test('hasTime returns true when prep time set', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
        prepTime: 15,
      );
      expect(recipe.hasTime, isTrue);
    });

    test('formats total time display', () {
      final recipe1 = Recipe(
        title: 'Recipe',
        ingredients: [],
        prepTime: 15,
        cookTime: 30,
      );
      expect(recipe1.totalTimeDisplay, equals('45 min'));
      
      final recipe2 = Recipe(
        title: 'Recipe',
        ingredients: [],
        prepTime: 30,
        cookTime: 90,
      );
      expect(recipe2.totalTimeDisplay, equals('2 hr'));
    });

    test('hasImage returns true when image set', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
        imagePath: './image.webp',
      );
      expect(recipe.hasImage, isTrue);
    });

    test('hasImage returns false when no image', () {
      final recipe = Recipe(title: 'Recipe', ingredients: []);
      expect(recipe.hasImage, isFalse);
    });
  });

  group('Recipe scaling', () {
    test('scales recipe to target servings', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 2, unit: 'cups', milliliters: 500),
          Ingredient(name: 'sugar', amount: 1, unit: 'cup', milliliters: 250),
        ],
        servings: 4,
      );
      
      final scaled = recipe.scaleTo(8);
      
      expect(scaled.servings, equals(8));
      expect(scaled.ingredients[0].amount, equals(4)); // Doubled
      expect(scaled.ingredients[0].milliliters, equals(1000));
      expect(scaled.ingredients[1].amount, equals(2));
      expect(scaled.ingredients[1].milliliters, equals(500));
    });

    test('throws when scaling recipe without servings', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [],
      );
      
      expect(() => recipe.scaleTo(8), throwsA(isA<StateError>()));
    });

    test('doubles recipe with servings', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 2, unit: 'cups', milliliters: 500),
        ],
        servings: 4,
      );
      
      final doubled = recipe.doubleRecipe();
      
      expect(doubled.servings, equals(8));
      expect(doubled.ingredients[0].amount, equals(4));
    });

    test('doubles recipe without servings (sets to 2)', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 1, unit: 'cup', milliliters: 250),
        ],
      );
      
      final doubled = recipe.doubleRecipe();
      
      expect(doubled.servings, equals(2));
      expect(doubled.ingredients[0].amount, equals(2));
    });

    test('triples recipe', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 1, unit: 'cup', milliliters: 250),
        ],
        servings: 4,
      );
      
      final tripled = recipe.tripleRecipe();
      
      expect(tripled.servings, equals(12));
      expect(tripled.ingredients[0].amount, equals(3));
    });
  });

  group('Recipe display', () {
    test('gets ingredients display', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 2, unit: 'cups', milliliters: 500),
          Ingredient(name: 'eggs', amount: 3, unit: ''),
        ],
      );
      
      final display = recipe.ingredientsDisplay;
      
      expect(display.length, equals(2));
      expect(display[0], contains('cups'));
      expect(display[0], contains('flour'));
      expect(display[0], contains('500ml'));
      expect(display[1], equals('3 eggs'));
    });

    test('gets ingredients short display', () {
      final recipe = Recipe(
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 2, unit: 'cups', milliliters: 500),
        ],
      );
      
      final display = recipe.ingredientsShortDisplay;
      
      expect(display[0], contains('cups'));
      expect(display[0], contains('flour'));
      expect(display[0], isNot(contains('ml')));
    });
  });

  group('Recipe copyWith', () {
    test('creates copy with same ID', () {
      final recipe = Recipe(
        id: 'test-id',
        title: 'Original',
        ingredients: [],
      );
      
      final copy = recipe.copyWith(title: 'Copy');
      
      expect(copy.id, equals('test-id'));
      expect(copy.title, equals('Copy'));
    });

    test('updates modified time by default', () async {
      final recipe = Recipe(title: 'Recipe', ingredients: []);
      final originalModified = recipe.modified;
      
      await Future.delayed(Duration(milliseconds: 10));
      
      final copy = recipe.copyWith(title: 'Updated');
      
      expect(copy.modified.isAfter(originalModified), isTrue);
    });
  });

  group('Recipe update', () {
    test('updates fields and sets modified time', () {
      final recipe = Recipe(
        title: 'Original',
        ingredients: [],
      );
      final originalModified = recipe.modified;
      
      recipe.update(title: 'Updated', prepTime: 15);
      
      expect(recipe.title, equals('Updated'));
      expect(recipe.prepTime, equals(15));
      expect(recipe.modified.isAfter(originalModified), isTrue);
    });
  });

  group('RecipeSerializer encode', () {
    test('encodes minimal recipe', () {
      final recipe = Recipe(
        id: 'test-id',
        title: 'Simple Recipe',
        ingredients: [],
      );
      
      final markdown = RecipeSerializer.encode(recipe);
      
      expect(markdown, contains('id:'));
      expect(markdown, contains('test-id'));
      expect(markdown, contains('title:'));
      expect(markdown, contains('Simple Recipe'));
      expect(markdown, contains('---'));
    });

    test('encodes recipe with ingredients', () {
      final recipe = Recipe(
        id: 'test-id',
        title: 'Recipe',
        ingredients: [
          Ingredient(name: 'flour', amount: 2, unit: 'cups', milliliters: 500),
        ],
      );
      
      final markdown = RecipeSerializer.encode(recipe);
      
      expect(markdown, contains('ingredients:'));
      expect(markdown, contains('name:'));
      expect(markdown, contains('flour'));
      expect(markdown, contains('amount:'));
      expect(markdown, contains('unit:'));
      expect(markdown, contains('cups'));
      expect(markdown, contains('ml:'));
      expect(markdown, contains('500'));
    });

    test('encodes recipe with body', () {
      final recipe = Recipe(
        title: 'Recipe',
        body: '# Instructions\n\nCook it',
        ingredients: [],
      );
      
      final markdown = RecipeSerializer.encode(recipe);
      
      expect(markdown, contains('# Instructions'));
      expect(markdown, contains('Cook it'));
    });

    test('encodes all optional fields', () {
      final recipe = Recipe(
        title: 'Full Recipe',
        ingredients: [],
        tags: ['tag1', 'tag2'],
        prepTime: 15,
        cookTime: 30,
        servings: 4,
        difficulty: 'easy',
        imagePath: './image.webp',
      );
      
      final markdown = RecipeSerializer.encode(recipe);
      
      expect(markdown, contains('tags:'));
      expect(markdown, contains('prep_time:'));
      expect(markdown, contains('cook_time:'));
      expect(markdown, contains('servings:'));
      expect(markdown, contains('difficulty:'));
      expect(markdown, contains('image:'));
    });
  });

  group('RecipeSerializer decode', () {
    test('decodes minimal markdown', () {
      final markdown = '''
---
id: test-id
title: Simple Recipe
created: 2024-01-15T10:00:00.000Z
modified: 2024-01-15T10:00:00.000Z
---
'''; 
      
      final recipe = RecipeSerializer.decode(markdown);
      
      expect(recipe.id, equals('test-id'));
      expect(recipe.title, equals('Simple Recipe'));
    });

    test('decodes recipe with ingredients', () {
      final markdown = '''
---
id: test-id
title: Recipe
ingredients:
  - name: flour
    amount: 2
    unit: cups
    ml: 500
created: 2024-01-15T10:00:00.000Z
modified: 2024-01-15T10:00:00.000Z
---
'''; 
      
      final recipe = RecipeSerializer.decode(markdown);
      
      expect(recipe.ingredients.length, equals(1));
      expect(recipe.ingredients[0].name, equals('flour'));
      expect(recipe.ingredients[0].amount, equals(2));
      expect(recipe.ingredients[0].milliliters, equals(500));
    });

    test('decodes recipe with body', () {
      final markdown = '''
---
id: test-id
title: Recipe
created: 2024-01-15T10:00:00.000Z
modified: 2024-01-15T10:00:00.000Z
---

# Instructions

Cook the pasta.
'''; 
      
      final recipe = RecipeSerializer.decode(markdown);
      
      expect(recipe.body, contains('# Instructions'));
      expect(recipe.body, contains('Cook the pasta'));
    });

    test('handles markdown without frontmatter', () {
      final markdown = '# Just a markdown file\n\nSome content';
      
      final recipe = RecipeSerializer.decode(markdown);
      
      expect(recipe.title, equals('Untitled'));
      expect(recipe.body, equals(markdown));
      expect(recipe.ingredients, isEmpty);
    });

    test('handles empty frontmatter', () {
      final markdown = '''
---
---

Body content
'''; 
      
      final recipe = RecipeSerializer.decode(markdown);
      
      expect(recipe.body, equals('Body content'));
    });
  });

  group('RecipeSerializer round-trip', () {
    test('encode then decode preserves data', () {
      final original = Recipe(
        id: 'test-id',
        title: 'Carbonara',
        body: '# Instructions\n\nCook pasta',
        ingredients: [
          Ingredient(name: 'pasta', amount: 400, unit: 'g', milliliters: 400),
          Ingredient(name: 'eggs', amount: 3, unit: ''),
        ],
        tags: ['italian'],
        prepTime: 15,
        cookTime: 20,
        servings: 4,
      );
      
      final markdown = RecipeSerializer.encode(original);
      final decoded = RecipeSerializer.decode(markdown);
      
      expect(decoded.id, equals(original.id));
      expect(decoded.title, equals(original.title));
      expect(decoded.body, equals(original.body));
      expect(decoded.ingredients.length, equals(original.ingredients.length));
      expect(decoded.tags, equals(original.tags));
      expect(decoded.prepTime, equals(original.prepTime));
      expect(decoded.cookTime, equals(original.cookTime));
      expect(decoded.servings, equals(original.servings));
    });
  });
}
