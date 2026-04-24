/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:uuid/uuid.dart';

import '../ingredients/ingredient.dart';

/// Represents a complete recipe with metadata and ingredients
class Recipe {
  final String id;
  String title;
  String body;  // Markdown content (instructions, notes)
  List<Ingredient> ingredients;
  List<String> tags;
  int? prepTime;      // minutes
  int? cookTime;      // minutes
  int? servings;
  String? difficulty; // easy, medium, hard
  String? imagePath;  // Relative path to image in repo
  DateTime created;
  DateTime modified;

  Recipe({
    String? id,
    required this.title,
    this.body = '',
    required this.ingredients,
    this.tags = const [],
    this.prepTime,
    this.cookTime,
    this.servings,
    this.difficulty,
    this.imagePath,
    DateTime? created,
    DateTime? modified,
  })  : id = id ?? const Uuid().v4(),
        created = created ?? DateTime.now(),
        modified = modified ?? DateTime.now();

  /// Total time (prep + cook)
  int? get totalTime {
    if (prepTime == null && cookTime == null) return null;
    return (prepTime ?? 0) + (cookTime ?? 0);
  }

  /// Formatted total time for display
  String? get totalTimeDisplay {
    final total = totalTime;
    if (total == null) return null;
    
    if (total < 60) {
      return '$total min';
    }
    final hours = total ~/ 60;
    final mins = total % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  /// Whether recipe has time information
  bool get hasTime => prepTime != null || cookTime != null;

  /// Whether recipe has an image
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Number of ingredients
  int get ingredientCount => ingredients.length;

  /// Scales the recipe to a new number of servings
  Recipe scaleTo(int targetServings) {
    if (servings == null || servings == 0) {
      throw StateError('Cannot scale recipe without base servings');
    }
    
    final factor = targetServings / servings!;
    
    return copyWith(
      servings: targetServings,
      ingredients: ingredients.map((i) => i.scale(factor)).toList(),
      modified: DateTime.now(),
    );
  }

  /// Doubles the recipe (party mode)
  Recipe doubleRecipe() {
    if (servings == null) {
      return copyWith(
        servings: 2,
        ingredients: ingredients.map((i) => i.scale(2)).toList(),
        modified: DateTime.now(),
      );
    }
    return scaleTo(servings! * 2);
  }

  /// Triples the recipe
  Recipe tripleRecipe() {
    if (servings == null) {
      return copyWith(
        servings: 3,
        ingredients: ingredients.map((i) => i.scale(3)).toList(),
        modified: DateTime.now(),
      );
    }
    return scaleTo(servings! * 3);
  }

  /// Gets ingredients formatted for display with ml conversion
  List<String> get ingredientsDisplay {
    return ingredients.map((i) => i.displayText).toList();
  }

  /// Gets ingredients without ml conversion
  List<String> get ingredientsShortDisplay {
    return ingredients.map((i) => i.shortDisplay).toList();
  }

  /// Creates a copy with modified fields
  Recipe copyWith({
    String? title,
    String? body,
    List<Ingredient>? ingredients,
    List<String>? tags,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    String? imagePath,
    DateTime? modified,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      ingredients: ingredients ?? this.ingredients,
      tags: tags ?? this.tags,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      imagePath: imagePath ?? this.imagePath,
      created: created,
      modified: modified ?? DateTime.now(),
    );
  }

  /// Updates the recipe (sets modified time)
  void update({
    String? title,
    String? body,
    List<Ingredient>? ingredients,
    List<String>? tags,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    String? imagePath,
  }) {
    if (title != null) this.title = title;
    if (body != null) this.body = body;
    if (ingredients != null) this.ingredients = ingredients;
    if (tags != null) this.tags = tags;
    if (prepTime != null) this.prepTime = prepTime;
    if (cookTime != null) this.cookTime = cookTime;
    if (servings != null) this.servings = servings;
    if (difficulty != null) this.difficulty = difficulty;
    if (imagePath != null) this.imagePath = imagePath;
    modified = DateTime.now();
  }

  @override
  String toString() => 'Recipe($title, ${ingredients.length} ingredients)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
