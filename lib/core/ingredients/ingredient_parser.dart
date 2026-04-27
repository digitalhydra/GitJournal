/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:gitjournal/core/ingredients/unit_converter.dart';
import 'package:gitjournal/utils/decimal_formatter.dart';

import 'ingredient.dart';
import 'parse_exception.dart';

/// Parses ingredient strings into structured Ingredient objects
/// 
/// Supported formats:
/// - "2 cups flour"
/// - "2 1/2 cups all-purpose flour"
/// - "250g sugar"
/// - "1/4 tsp salt"
/// - "3 eggs" (no unit)
class IngredientParser {
  final UnitConverter _converter;

  IngredientParser({UnitConverter? converter})
      : _converter = converter ?? UnitConverter();

  /// Common cooking units to recognize (English + Spanish)
  static final Set<String> _units = {
    // Volume - US (English)
    'cup', 'cups', 'c',
    'tbsp', 'tablespoon', 'tablespoons', 'tbs',
    'tsp', 'teaspoon', 'teaspoons',
    'fl oz', 'floz', 'fluid oz', 'fluid ounce', 'fluid ounces',
    'pt', 'pint', 'pints',
    'qt', 'quart', 'quarts',
    'gal', 'gallon', 'gallons',
    // Volume - Spanish
    'taza', 'tazas', 'tz',
    'cucharada', 'cucharadas', 'cda',
    'cucharadita', 'cucharaditas', 'cdta',
    'onzas', 'onza fluida', 'onzas fluidas',
    'pinta', 'pintas',
    'cuarto', 'cuartos',
    'galon', 'galones',
    // Volume - Metric
    'ml', 'milliliter', 'milliliters', 'mililitro', 'mililitros',
    'l', 'liter', 'liters', 'litre', 'litres', 'litro', 'litros',
    'cl', 'centiliter', 'centiliters', 'centilitro', 'centilitros',
    'dl', 'deciliter', 'deciliters', 'decilitro', 'decilitros',
    // Weight - English
    'g', 'gram', 'grams',
    'kg', 'kilogram', 'kilograms',
    'oz', 'ounce', 'ounces',
    'lb', 'lbs', 'pound', 'pounds',
    // Weight - Spanish
    'gr', 'gramo', 'gramos',
    'kilo', 'kilos', 'kilogramo', 'kilogramos',
    'onza',
    'libra', 'libras',
    // Count - English
    'piece', 'pieces',
    'slice', 'slices',
    'clove', 'cloves',
    'stick', 'sticks',
    'pinch', 'pinches',
    'dash', 'dashes',
    'can', 'cans',
    'bunch', 'bunches',
    'head', 'heads',
    'package', 'packages', 'pkg',
    // Count - Spanish
    'pieza', 'piezas', 'pedazo', 'pedazos',
    'rebanada', 'rebanadas',
    'diente', 'dientes',
    'barra', 'barras',
    'pizca', 'pizcas',
    'chorrito', 'chorritos',
    'lata', 'latas',
    'manojo', 'manojos',
    'cabeza', 'cabezas',
    'paquete', 'paquetes', 'pqte',
  };

  /// Parses an ingredient string
  /// 
  /// Throws [ParseException] if the string cannot be parsed
  Ingredient parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ParseException(input, 'Empty string');
    }

    // Try to extract amount, unit, and name
    final result = _extractParts(trimmed);
    
    if (result.amount == null) {
      throw ParseException(input, 'Missing amount');
    }

    if (result.name == null || result.name!.isEmpty) {
      throw ParseException(input, 'Missing ingredient name');
    }

    // Convert to milliliters if possible
    final ml = _converter.convert(
      result.amount!,
      result.unit ?? '',
      ingredient: result.name,
    );

    return Ingredient(
      name: result.name!,
      amount: result.amount!,
      unit: result.unit ?? '',
      milliliters: ml,
    );
  }

  /// Trys to parse without throwing
  /// Returns null if parsing fails
  Ingredient? tryParse(String input) {
    try {
      return parse(input);
    } on ParseException {
      return null;
    }
  }

  /// Extracts amount, unit, and name from input
  _ParseResult _extractParts(String input) {
    // Patterns to try, from most specific to least specific
    
    // Pattern 1: "2 1/2 cups all-purpose flour" (mixed number + unit)
    final mixedUnitPattern = RegExp(
      r'^(\d+\s+\d/\d+|\d/\d+|\d+\.?\d*)\s+(' + _unitPattern + r')\s+(.+)$',
      caseSensitive: false,
    );
    
    var match = mixedUnitPattern.firstMatch(input);
    if (match != null) {
      final amountStr = match.group(1)!;
      final unit = match.group(2)!.toLowerCase();
      final name = match.group(3)!.trim();
      
      final amount = DecimalFormatter.parse(amountStr);
      if (amount != null) {
        return _ParseResult(amount: amount, unit: unit, name: name);
      }
    }

    // Pattern 2: "2 cups flour" (simple number + unit)
    final simpleUnitPattern = RegExp(
      r'^(\d+\.?\d*)\s+(' + _unitPattern + r')\s+(.+)$',
      caseSensitive: false,
    );
    
    match = simpleUnitPattern.firstMatch(input);
    if (match != null) {
      final amountStr = match.group(1)!;
      final unit = match.group(2)!.toLowerCase();
      final name = match.group(3)!.trim();
      
      final amount = double.tryParse(amountStr);
      if (amount != null) {
        return _ParseResult(amount: amount, unit: unit, name: name);
      }
    }

    // Pattern 3: "250g sugar" (no space between amount and unit)
    final noSpacePattern = RegExp(
      r'^(\d+\.?\d*)(' + _unitPattern + r')\s+(.+)$',
      caseSensitive: false,
    );
    
    match = noSpacePattern.firstMatch(input);
    if (match != null) {
      final amountStr = match.group(1)!;
      final unit = match.group(2)!.toLowerCase();
      final name = match.group(3)!.trim();
      
      final amount = double.tryParse(amountStr);
      if (amount != null) {
        return _ParseResult(amount: amount, unit: unit, name: name);
      }
    }

    // Pattern 4: "3 eggs" (amount + name, no unit)
    // Only match if the second part is NOT a known unit
    final countPattern = RegExp(r'^(\d+)\s+(.+)$');
    match = countPattern.firstMatch(input);
    if (match != null) {
      final amountStr = match.group(1)!;
      final potentialName = match.group(2)!.trim().toLowerCase();
      
      // Check if the "name" part is actually just a unit (e.g., "2 cups")
      if (_isUnit(potentialName)) {
        // This is likely "2 cups" without a name, not "2 eggs"
        // Don't match here, let it fail
        return _ParseResult(name: ''); // Empty name will trigger error
      }
      
      final amount = double.tryParse(amountStr);
      if (amount != null) {
        return _ParseResult(amount: amount, unit: '', name: potentialName);
      }
    }

    // Pattern 5: Just a name (e.g., "salt to taste")
    // This fails because no amount - let caller decide
    return _ParseResult(name: input);
  }

  /// Pattern string for matching units
  static String get _unitPattern {
    // Sort by length (longest first) to match "tablespoons" before "tablespoon"
    final sorted = _units.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    // Escape special regex chars and join with |
    return sorted
        .map((u) => RegExp.escape(u))
        .join('|');
  }

  /// Checks if a string is a known unit
  static bool _isUnit(String str) {
    return _units.contains(str.toLowerCase());
  }
}

/// Internal class for parse results
class _ParseResult {
  final double? amount;
  final String? unit;
  final String? name;

  _ParseResult({this.amount, this.unit, this.name});
}
