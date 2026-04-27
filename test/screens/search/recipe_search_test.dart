/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/ingredients/ingredient.dart';
import 'package:gitjournal/core/recipe/recipe.dart';

/// Simple search function for testing
List<Recipe> searchRecipes(List<Recipe> recipes, String query) {
  if (query.isEmpty) {
    return recipes;
  }

  final lowerQuery = query.toLowerCase();

  return recipes.where((recipe) {
    // Search in title
    if (recipe.title.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Search in ingredients
    for (final ingredient in recipe.ingredients) {
      if (ingredient.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
    }

    // Search in tags
    for (final tag in recipe.tags) {
      if (tag.toLowerCase().contains(lowerQuery)) {
        return true;
      }
    }

    // Search in body/instructions
    if (recipe.body.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    return false;
  }).toList();
}

void main() {
  group('Recipe Search', () {
    final testRecipes = [
      Recipe(
        title: 'Pasta Carbonara',
        ingredients: [
          Ingredient(name: 'spaghetti', amount: 400, unit: 'g'),
          Ingredient(name: 'eggs', amount: 3, unit: ''),
          Ingredient(name: 'bacon', amount: 200, unit: 'g'),
          Ingredient(name: 'cheese', amount: 100, unit: 'g'),
        ],
        body: 'Cook pasta. Mix eggs and cheese. Fry bacon.',
        tags: ['italian', 'pasta', 'dinner'],
      ),
      Recipe(
        title: 'Chicken Curry',
        ingredients: [
          Ingredient(name: 'chicken', amount: 500, unit: 'g'),
          Ingredient(name: 'curry powder', amount: 2, unit: 'tbsp'),
          Ingredient(name: 'coconut milk', amount: 400, unit: 'ml'),
          Ingredient(name: 'rice', amount: 300, unit: 'g'),
        ],
        body: 'Cook chicken. Add curry. Simmer with coconut milk.',
        tags: ['indian', 'spicy', 'dinner'],
      ),
      Recipe(
        title: 'Chocolate Cake',
        ingredients: [
          Ingredient(name: 'flour', amount: 250, unit: 'g'),
          Ingredient(name: 'cocoa powder', amount: 50, unit: 'g'),
          Ingredient(name: 'sugar', amount: 200, unit: 'g'),
          Ingredient(name: 'eggs', amount: 3, unit: ''),
        ],
        body: 'Mix dry ingredients. Add eggs. Bake.',
        tags: ['dessert', 'baking', 'chocolate'],
      ),
      Recipe(
        title: 'Gazpacho',
        ingredients: [
          Ingredient(name: 'tomatoes', amount: 1, unit: 'kg'),
          Ingredient(name: 'cucumber', amount: 1, unit: ''),
          Ingredient(name: 'pepper', amount: 1, unit: ''),
          Ingredient(name: 'garlic', amount: 2, unit: 'cloves'),
        ],
        body: 'Blend all vegetables. Chill.',
        tags: ['spanish', 'cold', 'soup'],
        prepTime: 15,
        cookTime: 0,
      ),
    ];

    test('returns all recipes when query is empty', () {
      final results = searchRecipes(testRecipes, '');
      expect(results.length, equals(4));
    });

    test('searches by title', () {
      final results = searchRecipes(testRecipes, 'pasta');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Pasta Carbonara'));
    });

    test('searches by title case insensitive', () {
      final results = searchRecipes(testRecipes, 'PASTA');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Pasta Carbonara'));
    });

    test('searches by ingredient', () {
      final results = searchRecipes(testRecipes, 'eggs');
      expect(results.length, equals(2));
      expect(results.map((r) => r.title).toSet(),
          containsAll(['Pasta Carbonara', 'Chocolate Cake']));
    });

    test('searches by tag', () {
      final results = searchRecipes(testRecipes, 'dessert');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Chocolate Cake'));
    });

    test('searches by body content', () {
      final results = searchRecipes(testRecipes, 'blend');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Gazpacho'));
    });

    test('returns multiple matches', () {
      final results = searchRecipes(testRecipes, 'dinner');
      expect(results.length, equals(2));
      expect(results.map((r) => r.title).toSet(),
          containsAll(['Pasta Carbonara', 'Chicken Curry']));
    });

    test('returns empty list when no matches', () {
      final results = searchRecipes(testRecipes, 'pizza');
      expect(results.length, equals(0));
    });

    test('searches partial matches', () {
      final results = searchRecipes(testRecipes, 'chick');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Chicken Curry'));
    });

    test('searches Spanish content', () {
      final results = searchRecipes(testRecipes, 'gazpacho');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Gazpacho'));
    });
  });
}
