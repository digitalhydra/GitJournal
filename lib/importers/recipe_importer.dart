/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import '../core/ingredients/ingredient.dart';

/// Result of importing a recipe from external source
class ImportResult {
  final String? title;
  final String? description;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? imageUrl;
  final String sourceUrl;
  final bool success;
  final String? error;
  final List<String> missingFields;

  const ImportResult({
    this.title,
    this.description,
    this.ingredients = const [],
    this.instructions = const [],
    this.prepTime,
    this.cookTime,
    this.servings,
    this.imageUrl,
    required this.sourceUrl,
    this.success = true,
    this.error,
    this.missingFields = const [],
  });

  /// Whether the import was partial (some fields missing)
  bool get isPartial => missingFields.isNotEmpty;

  /// Whether this import has usable data
  bool get hasData => title != null || ingredients.isNotEmpty;

  /// Creates a copy with modified fields
  ImportResult copyWith({
    String? title,
    String? description,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? imageUrl,
    bool? success,
    String? error,
    List<String>? missingFields,
  }) {
    return ImportResult(
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl,
      success: success ?? this.success,
      error: error ?? this.error,
      missingFields: missingFields ?? this.missingFields,
    );
  }

  /// Creates a failed import result
  factory ImportResult.failure(String sourceUrl, String error) {
    return ImportResult(
      sourceUrl: sourceUrl,
      success: false,
      error: error,
    );
  }
}

/// Base interface for all recipe importers
abstract class RecipeImporter {
  /// Unique identifier for this importer type
  String get name;

  /// Human-readable description
  String get description;

  /// Supported URL patterns (for URL-based importers)
  List<String> get supportedDomains;

  /// Whether this importer can handle the given input
  bool canHandle(String input);

  /// Imports a recipe from the input
  /// 
  /// Input could be:
  /// - URL (for web importers)
  /// - File path (for file importers)
  /// - Raw text (for text importers)
  /// 
  /// Returns [ImportResult] with extracted data
  Future<ImportResult> import(String input);

}
