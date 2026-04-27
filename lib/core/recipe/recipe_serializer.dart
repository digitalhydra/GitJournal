/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:yaml/yaml.dart';

import '../ingredients/ingredient.dart';
import 'recipe.dart';

/// Serializes Recipe to/from YAML frontmatter + Markdown body format
/// 
/// Format:
/// ```markdown
/// ---
/// id: "uuid"
/// title: "Recipe Name"
/// ingredients:
///   - name: "flour"
///     amount: 2.0
///     unit: "cups"
///     ml: 500.0
/// ---
/// 
/// # Instructions
/// 
/// 1. Step one
/// 2. Step two
/// ```
class RecipeSerializer {
  static const String _separator = '---';
  
  /// Serializes a recipe to markdown string
  static String encode(Recipe recipe) {
    final buffer = StringBuffer();
    buffer.writeln(_separator);
    _writeYaml(recipe, buffer);
    buffer.writeln(_separator);
    
    // Add body if present
    if (recipe.body.isNotEmpty) {
      buffer.writeln();
      buffer.write(recipe.body);
    }
    
    return buffer.toString();
  }

  /// Writes recipe as YAML to buffer
  static void _writeYaml(Recipe recipe, StringBuffer buffer) {
    buffer.writeln('id: "${recipe.id}"');
    buffer.writeln('title: "${recipe.title}"');
    buffer.writeln('created: "${recipe.created.toIso8601String()}"');
    buffer.writeln('modified: "${recipe.modified.toIso8601String()}"');
    
    if (recipe.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in recipe.tags) {
        buffer.writeln('  - "$tag"');
      }
    }
    
    if (recipe.prepTime != null) {
      buffer.writeln('prep_time: ${recipe.prepTime}');
    }
    
    if (recipe.cookTime != null) {
      buffer.writeln('cook_time: ${recipe.cookTime}');
    }
    
    if (recipe.servings != null) {
      buffer.writeln('servings: ${recipe.servings}');
    }
    
    if (recipe.difficulty != null) {
      buffer.writeln('difficulty: "${recipe.difficulty}"');
    }
    
    if (recipe.imagePath != null) {
      buffer.writeln('image: "${recipe.imagePath}"');
    }
    
    if (recipe.isFavorite) {
      buffer.writeln('favorite: true');
    }
    
    if (recipe.ingredients.isNotEmpty) {
      buffer.writeln('ingredients:');
      for (final ing in recipe.ingredients) {
        buffer.writeln('  - name: "${ing.name}"');
        buffer.writeln('    amount: ${ing.amount}');
        buffer.writeln('    unit: "${ing.unit}"');
        if (ing.milliliters != null) {
          buffer.writeln('    ml: ${ing.milliliters}');
        }
      }
    }
  }

  /// Deserializes a markdown string to recipe
  static Recipe decode(String markdown) {
    final parts = _splitFrontmatter(markdown);
    
    if (parts == null) {
      // No frontmatter - treat entire content as body
      return Recipe(
        title: 'Untitled',
        body: markdown,
        ingredients: [],
      );
    }
    
    final yamlContent = parts.$1;
    final body = parts.$2;
    
    final yaml = loadYaml(yamlContent);
    
    if (yaml == null || yaml is! Map) {
      return Recipe(
        title: 'Untitled',
        body: body,
        ingredients: [],
      );
    }
    
    // Convert YamlMap to regular Map
    final yamlMap = <String, dynamic>{};
    for (final entry in yaml.entries) {
      yamlMap[entry.key.toString()] = entry.value;
    }
    
    return _fromYamlMap(yamlMap, body);
  }

  /// Splits markdown into frontmatter and body
  /// Returns (frontmatter, body) or null if no frontmatter
  static (String, String)? _splitFrontmatter(String markdown) {
    final lines = markdown.split('\n');
    
    if (lines.isEmpty || !lines.first.trim().startsWith(_separator)) {
      return null;
    }
    
    // Find closing separator
    int closeIndex = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == _separator) {
        closeIndex = i;
        break;
      }
    }
    
    if (closeIndex == -1) {
      return null;
    }
    
    final frontmatter = lines.sublist(1, closeIndex).join('\n');
    final body = lines.sublist(closeIndex + 1).join('\n').trim();
    
    return (frontmatter, body);
  }

  /// Creates recipe from YAML map and body
  static Recipe _fromYamlMap(Map<String, dynamic> yaml, String body) {
    // Parse ingredients
    List<Ingredient> ingredients = [];
    final ingredientsYaml = yaml['ingredients'];
    if (ingredientsYaml is List) {
      ingredients = ingredientsYaml
          .whereType<Map>()
          .map((m) => Ingredient.fromYaml(Map<String, dynamic>.from(m)))
          .toList();
    }
    
    // Parse tags
    List<String> tags = [];
    final tagsYaml = yaml['tags'];
    if (tagsYaml is List) {
      tags = tagsYaml.whereType<String>().toList();
    }
    
    // Parse dates
    DateTime? created;
    DateTime? modified;
    try {
      created = DateTime.parse(yaml['created'] as String);
    } catch (_) {}
    try {
      modified = DateTime.parse(yaml['modified'] as String);
    } catch (_) {}
    
    return Recipe(
      id: yaml['id'] as String?,
      title: yaml['title'] as String? ?? 'Untitled',
      body: body,
      ingredients: ingredients,
      tags: tags,
      prepTime: yaml['prep_time'] as int?,
      cookTime: yaml['cook_time'] as int?,
      servings: yaml['servings'] as int?,
      difficulty: yaml['difficulty'] as String?,
      imagePath: yaml['image'] as String?,
      isFavorite: yaml['favorite'] == true,
      created: created,
      modified: modified,
    );
  }
}
