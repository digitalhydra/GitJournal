/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:html/dom.dart';

/// Fallback parser that uses heuristics when schema.org isn't available
/// Looks for common patterns in recipe HTML
class HeuristicParser {
  /// Extracts recipe data using heuristic patterns
  static Map<String, dynamic> parse(Document document) {
    final result = <String, dynamic>{};
    
    // Try to find title
    result['title'] = _extractTitle(document);
    
    // Try to find ingredients
    result['ingredients'] = _extractIngredients(document);
    
    // Try to find instructions
    result['instructions'] = _extractInstructions(document);
    
    // Try to find times
    result['prepTime'] = _extractPrepTime(document);
    result['cookTime'] = _extractCookTime(document);
    
    // Try to find yield
    result['servings'] = _extractServings(document);
    
    return result;
  }

  static String? _extractTitle(Document document) {
    // Try h1 first, then title tag
    final h1 = document.querySelector('h1');
    if (h1 != null) {
      return h1.text.trim();
    }
    
    final title = document.querySelector('title');
    if (title != null) {
      // Often "Recipe Name | Site Name"
      final text = title.text.trim();
      final parts = text.split('|');
      return parts.first.trim();
    }
    
    return null;
  }

  static List<String> _extractIngredients(Document document) {
    final ingredients = <String>[];
    
    // Look for common ingredient section patterns
    final selectors = [
      '[class*="ingredient"] li',
      '[class*="Ingredient"] li',
      '[class*="ingredients"] li',
      '[class*="Ingredients"] li',
      '.wprm-recipe-ingredient',
      '.recipe-ingredient',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        for (final el in elements) {
          final text = el.text.trim();
          if (text.isNotEmpty && !_isCommonFalsePositive(text)) {
            ingredients.add(text);
          }
        }
        if (ingredients.isNotEmpty) break;
      }
    }
    
    // Fallback: look for lists near "Ingredients" heading
    if (ingredients.isEmpty) {
      final heading = _findHeading(document, 'ingredients');
      if (heading != null) {
        // Look for ul/ol after heading
        var nextEl = heading.nextElementSibling;
        while (nextEl != null) {
          if (nextEl.localName == 'ul' || nextEl.localName == 'ol') {
            for (final li in nextEl.querySelectorAll('li')) {
              final text = li.text.trim();
              if (text.isNotEmpty) {
                ingredients.add(text);
              }
            }
            break;
          }
          nextEl = nextEl.nextElementSibling;
        }
      }
    }
    
    return ingredients;
  }

  static List<String> _extractInstructions(Document document) {
    final instructions = <String>[];
    
    // Look for common instruction section patterns
    final selectors = [
      '[class*="instruction"] li',
      '[class*="Instruction"] li',
      '[class*="instructions"] li',
      '[class*="Instructions"] li',
      '[class*="direction"] li',
      '[class*="Direction"] li',
      '.wprm-recipe-instruction',
      '.recipe-instruction',
      '.recipe-step',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        for (final el in elements) {
          final text = el.text.trim();
          if (text.isNotEmpty) {
            instructions.add(text);
          }
        }
        if (instructions.isNotEmpty) break;
      }
    }
    
    // Fallback: look for lists near "Instructions" or "Directions" heading
    if (instructions.isEmpty) {
      for (final keyword in ['instructions', 'directions', 'method', 'steps']) {
        final heading = _findHeading(document, keyword);
        if (heading != null) {
          var nextEl = heading.nextElementSibling;
          while (nextEl != null) {
            if (nextEl.localName == 'ul' || nextEl.localName == 'ol') {
              for (final li in nextEl.querySelectorAll('li')) {
                final text = li.text.trim();
                if (text.isNotEmpty) {
                  instructions.add(text);
                }
              }
              break;
            }
            nextEl = nextEl.nextElementSibling;
          }
          if (instructions.isNotEmpty) break;
        }
      }
    }
    
    return instructions;
  }

  static int? _extractPrepTime(Document document) {
    return _extractTime(document, ['prep', 'preparation']);
  }

  static int? _extractCookTime(Document document) {
    return _extractTime(document, ['cook', 'cooking']);
  }

  static int? _extractTime(Document document, List<String> keywords) {
    // Look in common time element patterns
    final selectors = [
      '[class*="time"]',
      '[class*="Time"]',
      '.wprm-recipe-time',
      '.recipe-time',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final el in elements) {
        final text = el.text.toLowerCase();
        if (keywords.any((k) => text.contains(k))) {
          final minutes = _parseTimeText(text);
          if (minutes != null) return minutes;
        }
      }
    }
    
    return null;
  }

  static int? _extractServings(Document document) {
    final selectors = [
      '[class*="yield"]',
      '[class*="Yield"]',
      '[class*="serving"]',
      '[class*="Serving"]',
      '.wprm-recipe-servings',
      '.recipe-servings',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final el in elements) {
        final text = el.text;
        final match = RegExp(r'(\d+)').firstMatch(text);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    }
    
    return null;
  }

  static Element? _findHeading(Document document, String text) {
    final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    final lowerText = text.toLowerCase();
    
    for (final heading in headings) {
      if (heading.text.toLowerCase().contains(lowerText)) {
        return heading;
      }
    }
    
    return null;
  }

  static int? _parseTimeText(String text) {
    // Try to extract time from text like "15 minutes", "1 hour 30 min", etc.
    int totalMinutes = 0;
    
    // Hours
    final hourMatch = RegExp(r'(\d+)\s*hr').firstMatch(text);
    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    
    // Minutes
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(text);
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }
    
    return totalMinutes > 0 ? totalMinutes : null;
  }

  static bool _isCommonFalsePositive(String text) {
    // Filter out common non-ingredient items
    final falsePositives = [
      'ingredients',
      'instructions',
      'directions',
      'method',
      'notes',
      'tips',
    ];
    
    final lower = text.toLowerCase();
    return falsePositives.any((fp) => lower == fp);
  }
}
