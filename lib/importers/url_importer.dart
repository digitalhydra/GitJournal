/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

import '../core/ingredients/ingredient.dart';
import '../core/ingredients/ingredient_parser.dart';
import 'heuristic_parser.dart';
import 'rate_limiter.dart';
import 'recipe_importer.dart';
import 'schema_org_parser.dart';

/// Imports recipes from URLs using schema.org or heuristics
class UrlImporter implements RecipeImporter {
  final http.Client _client;
  final IngredientParser _ingredientParser;

  UrlImporter({
    http.Client? client,
    IngredientParser? ingredientParser,
  })  : _client = client ?? http.Client(),
        _ingredientParser = ingredientParser ?? IngredientParser();

  @override
  String get name => 'url';

  @override
  String get description => 'Import from recipe websites';

  @override
  List<String> get supportedDomains => [
    'allrecipes.com',
    'foodnetwork.com',
    'seriouseats.com',
    'bonappetit.com',
    'epicurious.com',
    'simplyrecipes.com',
    'minimalistbaker.com',
    'cookieandkate.com',
    'loveandlemons.com',
    'budgetbytes.com',
    'sallysbakingaddiction.com',
    'pinchofyum.com',
    'gimmesomeoven.com',
    'tasty.co',
    'delish.com',
    'bettycrocker.com',
    'pillsbury.com',
    'kingarthurbaking.com',
    'nytimes.com', // Cooking section
    'bbcgoodfood.com',
    'jamieoliver.com',
  ];

  @override
  bool canHandle(String input) {
    // Check if input looks like a URL
    final uri = Uri.tryParse(input);
    if (uri == null) return false;
    
    // Must have http/https scheme and a host
    return (uri.scheme == 'http' || uri.scheme == 'https') && 
           uri.host.isNotEmpty;
  }

  @override
  Future<ImportResult> import(String url) async {
    if (!canHandle(url)) {
      return ImportResult.failure(url, 'Invalid URL');
    }

    try {
      // Rate limit by domain
      final domain = RateLimiter.extractDomain(url);
      await RateLimiter.wait(domain);

      // Fetch page
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; RecipeJournal/1.0)',
        },
      );

      if (response.statusCode != 200) {
        return ImportResult.failure(
          url, 
          'HTTP ${response.statusCode}',
        );
      }

      // Parse HTML
      final document = parse(response.body);

      // Try schema.org first
      var data = SchemaOrgParser.parse(document);
      final usedSchemaOrg = data != null;

      // Fall back to heuristics
      if (data == null) {
        data = HeuristicParser.parse(document);
      }

      // Build import result
      return _buildResult(url, data, usedSchemaOrg: usedSchemaOrg);

    } on TimeoutException {
      return ImportResult.failure(url, 'Request timeout');
    } catch (e) {
      return ImportResult.failure(url, e.toString());
    }
  }

  ImportResult _buildResult(
    String url,
    Map<String, dynamic> data, {
    required bool usedSchemaOrg,
  }) {
    final missingFields = <String>[];

    // Parse ingredients
    final ingredients = <Ingredient>[];
    final rawIngredients = data['ingredients'] as List<String>? ?? [];
    
    for (final raw in rawIngredients) {
      final parsed = _ingredientParser.tryParse(raw);
      if (parsed != null) {
        ingredients.add(parsed);
      }
    }

    if (ingredients.isEmpty) {
      missingFields.add('ingredients');
    }

    // Check other fields
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      missingFields.add('title');
    }

    final instructions = data['instructions'] as List<String>? ?? [];
    if (instructions.isEmpty) {
      missingFields.add('instructions');
    }

    final prepTime = data['prepTime'] as int?;
    final cookTime = data['cookTime'] as int?;
    if (prepTime == null && cookTime == null) {
      missingFields.add('time');
    }

    final servings = data['servings'] as int?;
    if (servings == null) {
      missingFields.add('servings');
    }

    return ImportResult(
      sourceUrl: url,
      title: title,
      description: data['description'] as String?,
      ingredients: ingredients,
      instructions: instructions,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      imageUrl: data['image'] as String?,
      success: ingredients.isNotEmpty || title != null,
      missingFields: missingFields,
    );
  }

  /// Disposes resources
  void dispose() {
    _client.close();
  }
}
