/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'density_table.dart';

/// Converts cooking measurements to milliliters
/// Uses density table for dry goods (volume → weight → ml)
/// Direct conversion for liquids
class UnitConverter {
  final DensityTable _densityTable;

  UnitConverter({DensityTable? densityTable})
      : _densityTable = densityTable ?? DensityTable();

  /// Liquid volume conversions (direct, no density needed)
  /// All values are: milliliters per unit
  static const Map<String, double> _liquidConversions = {
    // Metric
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'liters': 1000.0,
    'cl': 10.0,
    'centiliter': 10.0,
    'dl': 100.0,
    'deciliter': 100.0,

    // US Customary
    'tsp': 4.92892,
    'teaspoon': 4.92892,
    'teaspoons': 4.92892,
    'tbsp': 14.7868,
    'tablespoon': 14.7868,
    'tablespoons': 14.7868,
    'floz': 29.5735,
    'fl_oz': 29.5735,
    'fluid_ounce': 29.5735,
    'fluid_ounces': 29.5735,
    'cup': 236.588,
    'cups': 236.588,
    'c': 236.588,
    'pt': 473.176,
    'pint': 473.176,
    'pints': 473.176,
    'qt': 946.353,
    'quart': 946.353,
    'quarts': 946.353,
    'gal': 3785.41,
    'gallon': 3785.41,
    'gallons': 3785.41,
  };

  /// Weight to volume (assuming water density: 1g = 1ml)
  /// These are approximate for general cooking
  static const Map<String, double> _weightConversions = {
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'oz': 28.3495,
    'ounce': 28.3495,
    'ounces': 28.3495,
    'lb': 453.592,
    'pound': 453.592,
    'pounds': 453.592,
  };

  /// Converts a measurement to milliliters
  /// 
  /// For liquids: direct volume conversion
  /// For dry goods with density: volume × density factor
  /// For weights: assumes water density (approximate)
  /// 
  /// Returns null if conversion not possible
  double? convert(
    double amount,
    String unit, {
    String? ingredient,
  }) {
    final normalizedUnit = _normalizeUnit(unit);

    // Try weight conversion first (always works, no density needed)
    final weightFactor = _weightConversions[normalizedUnit];
    if (weightFactor != null) {
      return amount * weightFactor;
    }

    // Check if this is a volume unit
    final isVolumeUnit = _convertToCups(1, normalizedUnit) != null;

    // If ingredient specified and it's a volume unit
    if (ingredient != null && isVolumeUnit) {
      // Try to get density for this ingredient
      if (_densityTable.hasDensity(ingredient)) {
        final density = _densityTable.getDensity(ingredient);
        if (density != null) {
          final unitInCups = _convertToCups(amount, normalizedUnit);
          if (unitInCups != null) {
            return unitInCups * density;
          }
        }
      }
      // Ingredient specified but no density - return null (can't convert accurately)
      return null;
    }

    // Try liquid conversion (fallback when no ingredient specified)
    final liquidFactor = _liquidConversions[normalizedUnit];
    if (liquidFactor != null) {
      return amount * liquidFactor;
    }

    return null;
  }

  /// Converts a measurement to cups (for density calculations)
  double? _convertToCups(double amount, String unit) {
    // Handle cup-based units
    if (unit == 'cup' || unit == 'cups' || unit == 'c') {
      return amount;
    }
    
    // Convert other units to cups
    final ml = _liquidConversions[unit];
    if (ml != null) {
      return amount * ml / _liquidConversions['cup']!;
    }

    return null;
  }

  /// Checks if a unit can be converted without knowing the ingredient
  bool isLiquidUnit(String unit) {
    final normalized = _normalizeUnit(unit);
    return _liquidConversions.containsKey(normalized) ||
           _weightConversions.containsKey(normalized);
  }

  /// Checks if an ingredient has density data
  bool canConvertDryGood(String ingredient) {
    return _densityTable.hasDensity(ingredient);
  }

  /// Gets all supported units
  static List<String> get supportedUnits {
    final units = <String>{};
    units.addAll(_liquidConversions.keys);
    units.addAll(_weightConversions.keys);
    return units.toList()..sort();
  }

  /// Gets supported liquid units only
  static List<String> get liquidUnits {
    return _liquidConversions.keys.toList()..sort();
  }

  /// Gets supported weight units only
  static List<String> get weightUnits {
    return _weightConversions.keys.toList()..sort();
  }

  /// Normalizes unit string for lookup
  static String _normalizeUnit(String unit) {
    return unit.toLowerCase().trim().replaceAll('.', '');
  }

  /// Formats a milliliter value as a readable string
  /// Includes original unit conversion for display
  static String formatWithUnit(double ml, {String? originalUnit}) {
    if (originalUnit != null) {
      return '${_formatDecimal(ml)}ml (${_formatDecimal(ml / _liquidConversions[_normalizeUnit(originalUnit)]!)} $originalUnit)';
    }
    return '${_formatDecimal(ml)}ml';
  }

  static String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
