/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/recipe/recipe.dart';
import '../core/recipe/recipe_serializer.dart';

/// Service for loading and managing recipes from the Git repository
class RecipeRepositoryService {
  final String repoPath;

  RecipeRepositoryService({required this.repoPath});

  /// Loads all recipes from the repository
  /// Searches for all .md files and parses them as recipes
  Future<List<Recipe>> loadAllRecipes() async {
    final recipes = <Recipe>[];
    
    try {
      final directory = Directory(repoPath);
      if (!await directory.exists()) {
        return recipes;
      }

      // Find all .md files recursively
      await for (final file in directory.list(recursive: true, followLinks: false)) {
        if (file is File && file.path.endsWith('.md')) {
          try {
            final content = await file.readAsString();
            final recipe = RecipeSerializer.decode(content);
            
            // Only add if it has a valid title
            if (recipe.title.isNotEmpty) {
              recipes.add(recipe);
            }
          } catch (e) {
            // Skip files that don't parse as recipes
            continue;
          }
        }
      }
    } catch (e) {
      // Return empty list on error
    }

    // Sort by modified date (newest first)
    recipes.sort((a, b) => b.modified.compareTo(a.modified));
    
    return recipes;
  }

  /// Loads a single recipe by its ID (UUID)
  Future<Recipe?> loadRecipeById(String id) async {
    final recipes = await loadAllRecipes();
    try {
      return recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Saves a recipe to the repository
  /// Creates or updates the markdown file
  Future<void> saveRecipe(Recipe recipe) async {
    final fileName = _sanitizeFileName(recipe.title);
    final filePath = p.join(repoPath, '$fileName.md');
    
    final content = RecipeSerializer.encode(recipe);
    final file = File(filePath);
    await file.writeAsString(content);
  }

  /// Deletes a recipe from the repository
  Future<void> deleteRecipe(Recipe recipe) async {
    final directory = Directory(repoPath);
    
    await for (final file in directory.list(recursive: true)) {
      if (file is File && file.path.endsWith('.md')) {
        try {
          final content = await file.readAsString();
          final r = RecipeSerializer.decode(content);
          if (r.id == recipe.id) {
            await file.delete();
            return;
          }
        } catch (_) {
          continue;
        }
      }
    }
  }

  /// Sanitizes a recipe title for use as a filename
  String _sanitizeFileName(String title) {
    // Remove characters that aren't safe in filenames
    var sanitized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
    
    // Add timestamp to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitized}_$timestamp';
  }
}
