/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';

/// Represents a recipe category with Spanish names
/// Categories are tag-based and hardcoded
class RecipeCategory {
  final String id;
  final String name;          // Spanish display name
  final String icon;          // Emoji
  final List<String> tags;    // Tags that match this category
  final String? imagePath;    // Random recipe image for category thumbnail
  final int recipeCount;

  const RecipeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.tags,
    this.imagePath,
    this.recipeCount = 0,
  });

  RecipeCategory copyWith({
    String? id,
    String? name,
    String? icon,
    List<String>? tags,
    String? imagePath,
    int? recipeCount,
  }) {
    return RecipeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      imagePath: imagePath ?? this.imagePath,
      recipeCount: recipeCount ?? this.recipeCount,
    );
  }

  /// Checks if a recipe's tags match this category
  bool matchesTags(List<String> recipeTags) {
    final recipeTagsLower = recipeTags.map((t) => t.toLowerCase()).toSet();
    final categoryTagsLower = tags.map((t) => t.toLowerCase()).toSet();
    return recipeTagsLower.intersection(categoryTagsLower).isNotEmpty;
  }
}

/// Default categories in Spanish
/// Hardcoded - 10 broad categories for recipe organization
final List<RecipeCategory> defaultCategories = [
  RecipeCategory(
    id: 'desayuno',
    name: 'Desayuno',
    icon: '🌅',
    tags: ['desayuno', 'breakfast', 'brunch', 'mañana'],
  ),
  RecipeCategory(
    id: 'almuerzo',
    name: 'Almuerzo',
    icon: '☀️',
    tags: ['almuerzo', 'lunch', 'comida', 'mediodía'],
  ),
  RecipeCategory(
    id: 'cena',
    name: 'Cena',
    icon: '🌙',
    tags: ['cena', 'dinner', 'supper', 'noche'],
  ),
  RecipeCategory(
    id: 'postres',
    name: 'Postres',
    icon: '🍰',
    tags: ['postres', 'dessert', 'dulce', 'dulces'],
  ),
  RecipeCategory(
    id: 'panaderia',
    name: 'Panadería',
    icon: '🥖',
    tags: ['panaderia', 'bakery', 'pan', 'pasteles', 'tartas'],
  ),
  RecipeCategory(
    id: 'bebidas',
    name: 'Bebidas',
    icon: '🥤',
    tags: ['bebidas', 'drinks', 'beverage', 'smoothie', 'jugo', 'café', 'té'],
  ),
  RecipeCategory(
    id: 'snacks',
    name: 'Snacks',
    icon: '🍿',
    tags: ['snacks', 'snack', 'aperitivo', 'botana'],
  ),
  RecipeCategory(
    id: 'sopas',
    name: 'Sopas',
    icon: '🍲',
    tags: ['sopas', 'soup', 'sopa', 'caldo', 'crema'],
  ),
  RecipeCategory(
    id: 'ensaladas',
    name: 'Ensaladas',
    icon: '🥗',
    tags: ['ensaladas', 'salad', 'ensalada', 'verduras'],
  ),
  RecipeCategory(
    id: 'aperitivos',
    name: 'Aperitivos',
    icon: '🍢',
    tags: ['aperitivos', 'appetizer', 'entradas', 'tapas'],
  ),
];

/// Gets all categories with their recipe counts
/// Filters out categories with 0 recipes
List<RecipeCategory> getActiveCategories(List<RecipeCategory> allCategories) {
  return allCategories.where((c) => c.recipeCount > 0).toList();
}

/// Finds category by ID
RecipeCategory? findCategoryById(String id) {
  try {
    return defaultCategories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

/// Finds all categories that match a recipe's tags
List<RecipeCategory> findCategoriesForRecipe(List<String> recipeTags) {
  return defaultCategories.where((c) => c.matchesTags(recipeTags)).toList();
}
