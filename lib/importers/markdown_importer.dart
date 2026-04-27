/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:yaml/yaml.dart';

import '../core/ingredients/ingredient.dart';
import '../core/ingredients/ingredient_parser.dart';
import 'recipe_importer.dart';

/// Imports recipes from Markdown files
/// 
/// Supports two formats:
/// 1. With YAML frontmatter (structured)
/// 2. Plain markdown with headers (unstructured)
class MarkdownImporter implements RecipeImporter {
  final IngredientParser _ingredientParser;

  MarkdownImporter({IngredientParser? ingredientParser})
      : _ingredientParser = ingredientParser ?? IngredientParser();

  @override
  String get name => 'markdown';

  @override
  String get description => 'Import from Markdown files';

  @override
  List<String> get supportedDomains => [];

  @override
  bool canHandle(String input) {
    // Check if it's markdown content or file path
    final lower = input.toLowerCase();
    return lower.endsWith('.md') || 
           lower.endsWith('.markdown') ||
           input.contains('#') ||  // Has markdown headers
           input.contains('---');  // Has frontmatter
  }

  @override
  Future<ImportResult> import(String input) async {
    try {
      String content;
      
      // If it looks like a file path, read it (for future file support)
      // For now, assume it's markdown content
      content = input;

      // Try YAML frontmatter first
      final frontmatterResult = _tryParseFrontmatter(content);
      if (frontmatterResult != null) {
        return _buildResultFromFrontmatter(input, frontmatterResult);
      }

      // Fall back to header-based parsing
      return _parseFromHeaders(input, content);

    } catch (e) {
      return ImportResult.failure(input, e.toString());
    }
  }

  /// Tries to parse YAML frontmatter
  /// Returns null if no frontmatter found
  Map<String, dynamic>? _tryParseFrontmatter(String content) {
    if (!content.trim().startsWith('---')) {
      return null;
    }

    final lines = content.split('\n');
    
    // Find closing ---
    int closeIndex = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        closeIndex = i;
        break;
      }
    }

    if (closeIndex == -1) {
      return null;
    }

    final frontmatter = lines.sublist(1, closeIndex).join('\n');
    
    try {
      final yaml = loadYaml(frontmatter);
      if (yaml is! Map) return null;
      
      // Convert YamlMap to regular Map
      final result = <String, dynamic>{};
      for (final entry in yaml.entries) {
        result[entry.key.toString()] = entry.value;
      }
      
      // Add body
      result['_body'] = lines.sublist(closeIndex + 1).join('\n').trim();
      
      return result;
    } catch (_) {
      return null;
    }
  }

  ImportResult _buildResultFromFrontmatter(
    String source,
    Map<String, dynamic> data,
  ) {
    final missingFields = <String>[];

    // Parse ingredients from frontmatter
    final ingredients = <Ingredient>[];
    final rawIngredients = data['ingredients'];
    
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map) {
          // Structured ingredient
          try {
            ingredients.add(Ingredient(
              name: item['name']?.toString() ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
              unit: item['unit']?.toString() ?? '',
              milliliters: (item['ml'] as num?)?.toDouble(),
            ));
          } catch (_) {
            // Skip invalid ingredients
          }
        } else if (item is String) {
          // Text ingredient - try to parse
          final parsed = _ingredientParser.tryParse(item);
          if (parsed != null) {
            ingredients.add(parsed);
          }
        }
      }
    }

    if (ingredients.isEmpty) {
      missingFields.add('ingredients');
    }

    // Get title
    final title = data['title']?.toString();
    if (title == null || title.isEmpty) {
      missingFields.add('title');
    }

    // Get instructions from body
    final body = data['_body']?.toString() ?? '';
    final instructions = _extractInstructionsFromBody(body);
    
    if (instructions.isEmpty) {
      missingFields.add('instructions');
    }

    // Get times
    int? prepTime;
    int? cookTime;
    
    if (data['prep_time'] != null) {
      prepTime = (data['prep_time'] as num).toInt();
    }
    if (data['cook_time'] != null) {
      cookTime = (data['cook_time'] as num).toInt();
    }

    if (prepTime == null && cookTime == null) {
      missingFields.add('time');
    }

    // Get servings
    final servings = data['servings'] != null 
        ? (data['servings'] as num).toInt()
        : null;
    if (servings == null) {
      missingFields.add('servings');
    }

    return ImportResult(
      sourceUrl: source,
      title: title,
      description: data['description']?.toString(),
      ingredients: ingredients,
      instructions: instructions,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      imageUrl: data['image']?.toString(),
      success: ingredients.isNotEmpty || title != null,
      missingFields: missingFields,
    );
  }

  /// Parses markdown without frontmatter using headers
  ImportResult _parseFromHeaders(String source, String content) {
    final missingFields = <String>[];

    // Extract title from first H1
    String? title;
    final h1Match = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    if (h1Match != null) {
      title = h1Match.group(1)!.trim();
    }

    if (title == null || title.isEmpty) {
      missingFields.add('title');
    }

    // Extract ingredients from "Ingredients" section
    final ingredients = _extractIngredientsFromBody(content);
    if (ingredients.isEmpty) {
      missingFields.add('ingredients');
    }

    // Extract instructions from "Instructions" or "Directions" section
    final instructions = _extractInstructionsFromBody(content);
    if (instructions.isEmpty) {
      missingFields.add('instructions');
    }

    return ImportResult(
      sourceUrl: source,
      title: title,
      ingredients: ingredients,
      instructions: instructions,
      success: ingredients.isNotEmpty || title != null,
      missingFields: missingFields,
    );
  }

  /// Extracts ingredients from markdown body
  List<Ingredient> _extractIngredientsFromBody(String content) {
    final ingredients = <Ingredient>[];

    // Look for "Ingredients" or "Ingredientes" header (English + Spanish)
    final pattern = RegExp(
      r'##?\s*(?:ingredients?|ingredientes)\s*\n+((?:[\s\S]*?))(?=##?|$)',
      caseSensitive: false,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      final section = match.group(1)!;
      
      // Parse list items
      final items = section.split('\n');
      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          final text = trimmed.substring(2);
          final parsed = _ingredientParser.tryParse(text);
          if (parsed != null) {
            ingredients.add(parsed);
          }
        } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
          // Numbered list
          final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '');
          final parsed = _ingredientParser.tryParse(text);
          if (parsed != null) {
            ingredients.add(parsed);
          }
        }
      }
    }

    return ingredients;
  }

  /// Extracts instructions from markdown body
  List<String> _extractInstructionsFromBody(String content) {
    final instructions = <String>[];

    // Look for "Instructions", "Directions", "Steps" or Spanish variants
    final pattern = RegExp(
      r'##?\s*(?:instructions?|directions?|steps?|instrucciones?|preparaci[óo]n|pasos?)\s*\n+((?:[\s\S]*?))(?=##?|$)',
      caseSensitive: false,
    );
    
    final match = pattern.firstMatch(content);
    if (match != null) {
      final section = match.group(1)!;
      
      // Parse list items
      final items = section.split('\n');
      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          instructions.add(trimmed.substring(2));
        } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
          // Numbered list
          instructions.add(trimmed.replaceFirst(RegExp(r'^\d+\.\s'), ''));
        } else if (trimmed.isNotEmpty) {
          // Plain text lines
          instructions.add(trimmed);
        }
      }
    }

    return instructions.where((s) => s.isNotEmpty).toList();
  }
}
