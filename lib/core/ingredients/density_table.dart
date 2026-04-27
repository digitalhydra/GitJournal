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
    // Flours & Powders - English
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
    // Flours & Powders - Spanish
    'harina': 208.0,
    'harina_de_trigo': 208.0,
    'harina_para_todo_uso': 208.0,
    'harina_de_pan': 208.0,
    'harina_de_pastel': 208.0,
    'azucar_glas': 200.0,
    'azucar_en_polvo': 200.0,
    'cacao_en_polvo': 125.0,
    'maicena': 240.0,
    'fecula_de_maiz': 240.0,
    'polvo_para_hornear': 230.0,
    'bicarbonato': 230.0,
    'bicarbonato_de_sodio': 230.0,

    // Sugars - English
    'sugar': 250.0,
    'granulated_sugar': 250.0,
    'white_sugar': 250.0,
    'brown_sugar': 275.0,
    'light_brown_sugar': 275.0,
    'dark_brown_sugar': 275.0,
    // Sugars - Spanish
    'azucar': 250.0,
    'azucar_blanca': 250.0,
    'azucar_granulada': 250.0,
    'azucar_morena': 275.0,
    'azucar_mascabado': 275.0,
    'piloncillo': 275.0,

    // Fats & Oils - English
    'butter': 237.0,
    'oil': 250.0,
    'vegetable_oil': 250.0,
    'olive_oil': 250.0,
    'coconut_oil': 250.0,
    'shortening': 205.0,
    // Fats & Oils - Spanish
    'mantequilla': 237.0,
    'aceite': 250.0,
    'aceite_vegetal': 250.0,
    'aceite_de_oliva': 250.0,
    'aceite_de_coco': 250.0,
    'manteca': 205.0,
    'manteca_vegetal': 205.0,

    // Liquids - English
    'milk': 244.0,
    'whole_milk': 244.0,
    'water': 237.0,
    'honey': 340.0,
    // Liquids - Spanish
    'leche': 244.0,
    'leche_entera': 244.0,
    'agua': 237.0,
    'miel': 340.0,
    'miel_de_abeja': 340.0,

    // Grains & Dry Goods - English
    'rice': 231.0,
    'white_rice': 231.0,
    'oats': 150.0,
    'rolled_oats': 150.0,
    'quick_oats': 150.0,
    // Grains & Dry Goods - Spanish
    'arroz': 231.0,
    'arroz_blanco': 231.0,
    'avena': 150.0,
    'hojuelas_de_avena': 150.0,
    'avena_en_hojuelas': 150.0,

    // Extras - English
    'salt': 273.0,
    'table_salt': 273.0,
    'kosher_salt': 250.0,
    'chocolate_chips': 170.0,
    'nuts': 150.0,
    'chopped_nuts': 150.0,
    'raisins': 170.0,
    'yeast': 224.0,
    'active_dry_yeast': 224.0,
    // Extras - Spanish
    'sal': 273.0,
    'sal_de_mesa': 273.0,
    'sal_kosher': 250.0,
    'chispas_de_chocolate': 170.0,
    'nueces': 150.0,
    'nueces_picadas': 150.0,
    'pasas': 170.0,
    'levadura': 224.0,
    'levadura_seca': 224.0,
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

    final dirPath = p.join(_repoPath, '.recipejournal');
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
  /// "Azúcar Morena" → "azucar_morena"
  static String _normalizeName(String name) {
    var normalized = name.toLowerCase();
    
    // Replace accented Spanish characters with ASCII equivalents
    normalized = normalized
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u');
    
    return normalized
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
