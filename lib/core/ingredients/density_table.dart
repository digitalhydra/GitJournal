/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Manages ingredient densities for volume-to-weight conversion
/// Densities stored as: milliliters per US cup (240ml volume)
/// 
/// User overrides stored in: .recipejournal/densities.json
class DensityTable {
  /// 20 common ingredient densities (ml per cup)
  static const Map<String, double> _defaults = {
    // Flours & Powders
    'flour': 208.0,
    'all_purpose_flour': 208.0,
    'bread_flour': 208.0,
    'cake_flour': 208.0,
    'powdered_sugar': 200.0,
    'confectioners_sugar': 200.0,
    'cocoa_powder': 125.0,
    'cornstarch': 240.0,
    'baking_powder': 230.0,
    'baking_soda': 230.0,

    // Sugars
    'sugar': 250.0,
    'granulated_sugar': 250.0,
    'white_sugar': 250.0,
    'brown_sugar': 275.0,
    'light_brown_sugar': 275.0,
    'dark_brown_sugar': 275.0,

    // Fats & Oils
    'butter': 237.0,
    'oil': 250.0,
    'vegetable_oil': 250.0,
    'olive_oil': 250.0,
    'coconut_oil': 250.0,
    'shortening': 205.0,

    // Liquids
    'milk': 244.0,
    'whole_milk': 244.0,
    'water': 237.0,
    'honey': 340.0,

    // Grains & Dry Goods
    'rice': 231.0,
    'white_rice': 231.0,
    'oats': 150.0,
    'rolled_oats': 150.0,
    'quick_oats': 150.0,

    // Extras
    'salt': 273.0,
    'table_salt': 273.0,
    'kosher_salt': 250.0,
    'chocolate_chips': 170.0,
    'nuts': 150.0,
    'chopped_nuts': 150.0,
    'raisins': 170.0,
    'yeast': 224.0,
    'active_dry_yeast': 224.0,
  };

  final Map<String, double> _userOverrides;
  final String? _repoPath;

  /// Creates density table with optional user overrides
  DensityTable({Map<String, double>? userOverrides, String? repoPath})
      : _userOverrides = userOverrides ?? {},
        _repoPath = repoPath;

  /// Gets density for an ingredient (ml per cup)
  /// Returns null if ingredient not found
  double? getDensity(String ingredient) {
    final normalized = _normalizeName(ingredient);
    
    // Check user overrides first
    if (_userOverrides.containsKey(normalized)) {
      return _userOverrides[normalized];
    }
    
    // Fall back to defaults
    return _defaults[normalized];
  }

  /// Checks if ingredient has a known density
  bool hasDensity(String ingredient) {
    return getDensity(ingredient) != null;
  }

  /// Adds or updates a user override
  void setDensity(String ingredient, double mlPerCup) {
    _userOverrides[_normalizeName(ingredient)] = mlPerCup;
  }

  /// Removes a user override
  void removeDensity(String ingredient) {
    _userOverrides.remove(_normalizeName(ingredient));
  }

  /// Gets all available densities (defaults + user overrides)
  Map<String, double> get allDensities {
    return {..._defaults, ..._userOverrides};
  }

  /// Gets only user overrides
  Map<String, double> get userOverrides => Map.unmodifiable(_userOverrides);

  /// Gets only default densities
  Map<String, double> get defaults => Map.unmodifiable(_defaults);

  /// Loads user overrides from JSON file in repo
  /// Path: .recipejournal/densities.json
  static Future<DensityTable> loadFromRepo(String repoPath) async {
    final filePath = p.join(repoPath, '.recipejournal', 'densities.json');
    final file = File(filePath);

    Map<String, double> overrides = {};

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        
        overrides = json.map((key, value) {
          return MapEntry(_normalizeName(key), (value as num).toDouble());
        });
      } catch (e) {
        // Ignore parse errors, use empty overrides
        overrides = {};
      }
    }

    return DensityTable(userOverrides: overrides, repoPath: repoPath);
  }

  /// Saves user overrides to JSON file in repo
  Future<void> saveToRepo() async {
    if (_repoPath == null) {
      throw StateError('No repo path set');
    }

    final dirPath = p.join(_repoPath!, '.recipejournal');
    final filePath = p.join(dirPath, 'densities.json');

    // Create directory if needed
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Sort for consistent output
    final sorted = Map.fromEntries(
      _userOverrides.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final json = const JsonEncoder.withIndent('  ').convert(sorted);
    await File(filePath).writeAsString(json);
  }

  /// Normalizes ingredient name for lookup
  /// "All-Purpose Flour" → "all_purpose_flour"
  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '') // Keep letters, numbers, spaces, underscores, hyphens
        .replaceAll(RegExp(r'[-\s]+'), '_')       // Replace hyphens and spaces with underscore
        .replaceAll(RegExp(r'_+'), '_')           // Collapse multiple underscores
        .trim()
        .replaceAll(RegExp(r'^_+|_+$'), '');      // Remove leading/trailing underscores
  }

  /// Lists all ingredients that have densities
  List<String> listIngredients() {
    return allDensities.keys.toList()..sort();
  }
}
