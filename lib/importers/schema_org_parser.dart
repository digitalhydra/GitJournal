/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';

import 'package:html/dom.dart';

/// Parses recipe data from schema.org JSON-LD structured data
class SchemaOrgParser {
  /// Extracts recipe from HTML document
  static Map<String, dynamic>? parse(Document document) {
    // Find all JSON-LD script tags
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');
    
    for (final script in scripts) {
      final jsonText = script.text.trim();
      if (jsonText.isEmpty) continue;
      
      try {
        final data = jsonDecode(jsonText);
        
        // Handle @graph structure
        if (data is Map && data.containsKey('@graph')) {
          final graph = data['@graph'] as List;
          for (final item in graph) {
            if (_isRecipe(item)) {
              return _extractRecipe(item);
            }
          }
        }
        
        // Handle direct recipe
        if (_isRecipe(data)) {
          return _extractRecipe(data);
        }
      } catch (_) {
        // Ignore JSON parse errors
        continue;
      }
    }
    
        return null;
  }

  static bool _isRecipe(dynamic data) {
    if (data is! Map) return false;
    
    final type = data['@type'];
    if (type is String) {
      return type == 'Recipe';
    }
    if (type is List) {
      return type.contains('Recipe');
    }
    return false;
  }

  static Map<String, dynamic> _extractRecipe(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    // Basic fields
    result['title'] = _extractText(data['name']);
    result['description'] = _extractText(data['description']);
    result['image'] = _extractImage(data['image']);
    
    // Time fields
    result['prepTime'] = _parseDuration(data['prepTime']);
    result['cookTime'] = _parseDuration(data['cookTime']);
    result['totalTime'] = _parseDuration(data['totalTime']);
    
    // Yield/servings
    result['servings'] = _parseYield(data['recipeYield'] ?? data['yield']);
    
    // Ingredients
    result['ingredients'] = _extractIngredients(data['recipeIngredient']);
    
    // Instructions
    result['instructions'] = _extractInstructions(data['recipeInstructions']);
    
    return result;
  }

  static String? _extractText(dynamic value) {
    if (value is String) return value.trim();
    return null;
  }

  static String? _extractImage(dynamic value) {
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String) return first;
      if (first is Map) return first['url'] as String?;
    }
    if (value is Map) return value['url'] as String?;
    return null;
  }

  static int? _parseDuration(dynamic value) {
    if (value == null) return null;
    
    String durationStr;
    if (value is String) {
      durationStr = value;
    } else if (value is Map) {
      durationStr = value['duration'] as String? ?? '';
    } else {
      return null;
    }
    
    // Parse ISO 8601 duration: PT15M, PT1H30M, etc.
    if (durationStr.startsWith('PT')) {
      int minutes = 0;
      
      final hourMatch = RegExp(r'(\d+)H').firstMatch(durationStr);
      if (hourMatch != null) {
        minutes += int.parse(hourMatch.group(1)!) * 60;
      }
      
      final minMatch = RegExp(r'(\d+)M').firstMatch(durationStr);
      if (minMatch != null) {
        minutes += int.parse(minMatch.group(1)!);
      }
      
      return minutes > 0 ? minutes : null;
    }
    
    // Try parsing plain number as minutes
    final plainMinutes = int.tryParse(durationStr);
    if (plainMinutes != null) return plainMinutes;
    
    return null;
  }

  static int? _parseYield(dynamic value) {
    if (value == null) return null;
    
    String yieldStr;
    if (value is String) {
      yieldStr = value;
    } else if (value is List && value.isNotEmpty) {
      yieldStr = value.first.toString();
    } else {
      yieldStr = value.toString();
    }
    
    // Extract number from strings like "4 servings", "makes 6", etc.
    final match = RegExp(r'(\d+)').firstMatch(yieldStr);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    
    return null;
  }

  static List<String> _extractIngredients(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().map((s) => s.trim()).toList();
    }
    if (value is String) return [value.trim()];
    return [];
  }

  static List<String> _extractInstructions(dynamic value) {
    if (value == null) return [];
    
    final instructions = <String>[];
    
    if (value is List) {
      for (final item in value) {
        if (item is String) {
          instructions.add(item.trim());
        } else if (item is Map) {
          // HowToStep structure
          final text = item['text'] ?? item['name'];
          if (text is String) {
            instructions.add(text.trim());
          }
        }
      }
    } else if (value is String) {
      // Split by newlines if it's a single string
      instructions.addAll(
        value.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty)
      );
    }
    
    return instructions;
  }
}
