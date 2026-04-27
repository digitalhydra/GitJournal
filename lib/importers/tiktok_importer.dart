/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../core/ingredients/ingredient.dart';
import '../core/ingredients/ingredient_parser.dart';
import 'rate_limiter.dart';
import 'recipe_importer.dart';

/// Imports recipes from TikTok videos by extracting caption text
/// 
/// Uses WebView to load TikTok page and extract metadata
/// since TikTok blocks direct HTTP requests
class TikTokImporter implements RecipeImporter {
  final IngredientParser _ingredientParser;
  HeadlessInAppWebView? _webView;

  TikTokImporter({IngredientParser? ingredientParser})
      : _ingredientParser = ingredientParser ?? IngredientParser();

  @override
  String get name => 'tiktok';

  @override
  String get description => 'Import from TikTok recipe videos';

  @override
  List<String> get supportedDomains => ['tiktok.com', 'vm.tiktok.com'];

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('tiktok.com') || 
           lower.contains('vm.tiktok.com');
  }

  @override
  Future<ImportResult> import(String url) async {
    if (!canHandle(url)) {
      return ImportResult.failure(url, 'Not a TikTok URL');
    }

    try {
      // Rate limit
      await RateLimiter.wait('tiktok.com');

      // Load page in headless WebView
      final html = await _loadWithWebView(url);
      
      // Extract from meta tags
      final title = _extractTitle(html);
      final description = _extractDescription(html);
      
      // Parse caption for recipe structure
      final parsed = _parseCaption(description);
      
      // Build missing fields list
      final missingFields = <String>[];
      if (parsed.title == null || parsed.title!.isEmpty) {
        missingFields.add('title');
      }
      if (parsed.ingredients.isEmpty) {
        missingFields.add('ingredients');
      }
      if (parsed.instructions.isEmpty) {
        missingFields.add('instructions');
      }

      return ImportResult(
        sourceUrl: url,
        title: parsed.title ?? title,
        description: description,
        ingredients: parsed.ingredients,
        instructions: parsed.instructions,
        imageUrl: _extractThumbnail(html),
        success: true,
        missingFields: missingFields,
      );

    } catch (e) {
      return ImportResult.failure(url, e.toString());
    }
  }

  /// Loads URL in headless WebView and returns HTML
  Future<String> _loadWithWebView(String url) async {
    String? result;
    
    _webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onLoadStop: (controller, uri) async {
        // Wait a bit for JavaScript to execute
        await Future.delayed(Duration(seconds: 2));
        result = await controller.getHtml();
      },
    );

    await _webView!.run();
    
    // Wait for load to complete (with timeout)
    var attempts = 0;
    while (result == null && attempts < 30) {
      await Future.delayed(Duration(milliseconds: 500));
      attempts++;
    }
    
    await _webView?.dispose();
    _webView = null;
    
    if (result == null) {
      throw TimeoutException('Failed to load TikTok page');
    }
    
    return result!;
  }

  /// Extracts title from meta tags
  String? _extractTitle(String html) {
    final match = RegExp(
      r"""<meta[^>]*property=["']og:title["'][^>]*content=["']([^"']*)""",
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1);
  }

  /// Extracts description from meta tags
  String? _extractDescription(String html) {
    // Try og:description first
    var match = RegExp(
      r"""<meta[^>]*property=["']og:description["'][^>]*content=["']([^"']*)""",
      caseSensitive: false,
    ).firstMatch(html);
    
    if (match != null) return match.group(1);
    
    // Fallback to regular description
    match = RegExp(
      r"""<meta[^>]*name=["']description["'][^>]*content=["']([^"']*)""",
      caseSensitive: false,
    ).firstMatch(html);
    
    return match?.group(1);
  }

  /// Extracts thumbnail URL from meta tags
  String? _extractThumbnail(String html) {
    final match = RegExp(
      r"""<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']*)""",
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1);
  }

  /// Parses TikTok caption for recipe structure
  _ParsedCaption _parseCaption(String? caption) {
    if (caption == null || caption.isEmpty) {
      return _ParsedCaption();
    }

    String? title;
    final ingredients = <Ingredient>[];
    final instructions = <String>[];

    // Remove hashtags and mentions for parsing
    final cleanCaption = caption
        .replaceAll(RegExp(r'#\w+'), '')
        .replaceAll(RegExp(r'@\w+'), '')
        .trim();

    // Try to find title (first line or sentence)
    final lines = cleanCaption.split('\n');
    if (lines.isNotEmpty && lines.first.length < 100) {
      title = lines.first.trim();
    }

    // Look for "Ingredients:" or "Ingredientes:" marker (English + Spanish)
    final ingredientsMatch = RegExp(
      r'(?:ingredients?|ingredientes):?\s*([^\n]+(?:\n[^\n]+)*?)(?=instructions?|directions?|steps?|instrucciones?|preparación?|preparacion?|$)',
      caseSensitive: false,
    ).firstMatch(cleanCaption);

    if (ingredientsMatch != null) {
      final ingredientsText = ingredientsMatch.group(1)!;
      
      // Split by commas, newlines, or bullets
      final items = ingredientsText.split(RegExp(r'[,\n•\-]+'));
      
      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          final parsed = _ingredientParser.tryParse(trimmed);
          if (parsed != null) {
            ingredients.add(parsed);
          }
        }
      }
    }

    // Look for "Instructions:" or "Directions:" marker (English + Spanish)
    final instructionsMatch = RegExp(
      r'(?:instructions?|directions?|steps?|instrucciones?|preparación?|preparacion?|pasos?):?\s*(.+?)(?=#|$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleanCaption);

    if (instructionsMatch != null) {
      final instructionsText = instructionsMatch.group(1)!;
      
      // Split by numbers (1. 2. 3.) or newlines
      final steps = instructionsText.split(RegExp(r'\n|\d+\.\s+'));
      
      for (final step in steps) {
        final trimmed = step.trim();
        if (trimmed.isNotEmpty && trimmed.length > 5) {
          instructions.add(trimmed);
        }
      }
    }

    return _ParsedCaption(
      title: title,
      ingredients: ingredients,
      instructions: instructions,
    );
  }

  /// Disposes the WebView
  void dispose() {
    _webView?.dispose();
  }
}

/// Internal class for parsed caption
class _ParsedCaption {
  final String? title;
  final List<Ingredient> ingredients;
  final List<String> instructions;

  _ParsedCaption({
    this.title,
    this.ingredients = const [],
    this.instructions = const [],
  });
}

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
