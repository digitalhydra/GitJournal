/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/importers/schema_org_parser.dart';
import 'package:html/parser.dart';

void main() {
  group('SchemaOrgParser', () {
    test('parses simple recipe', () {
      final html = '''
<!DOCTYPE html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Chocolate Cake",
  "description": "A delicious chocolate cake",
  "prepTime": "PT15M",
  "cookTime": "PT30M",
  "recipeYield": "8 servings",
  "recipeIngredient": [
    "2 cups flour",
    "1 cup sugar",
    "3 eggs"
  ],
  "recipeInstructions": [
    "Mix dry ingredients",
    "Add wet ingredients",
    "Bake at 350F"
  ]
}
</script>
</head>
</html>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result, isNotNull);
      expect(result!['title'], equals('Chocolate Cake'));
      expect(result['description'], equals('A delicious chocolate cake'));
      expect(result['prepTime'], equals(15));
      expect(result['cookTime'], equals(30));
      expect(result['servings'], equals(8));
      expect(result['ingredients'], hasLength(3));
      expect(result['ingredients'][0], equals('2 cups flour'));
      expect(result['instructions'], hasLength(3));
    });

    test('parses recipe from @graph structure', () {
      final html = '''
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebPage",
      "name": "Page"
    },
    {
      "@type": "Recipe",
      "name": "Pasta",
      "recipeIngredient": ["1 lb pasta"]
    }
  ]
}
</script>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result, isNotNull);
      expect(result!['title'], equals('Pasta'));
    });

    test('returns null when no recipe found', () {
      final html = '''
<html>
<head>
<script type="application/ld+json">
{
  "@type": "WebPage",
  "name": "Not a Recipe"
}
</script>
</head>
</html>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result, isNull);
    });

    test('parses HowToStep instructions', () {
      final html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "recipeInstructions": [
    {
      "@type": "HowToStep",
      "text": "Step one"
    },
    {
      "@type": "HowToStep",
      "name": "Step two name",
      "text": "Step two"
    }
  ]
}
</script>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result!['instructions'], equals(['Step one', 'Step two']));
    });

    test('parses image from various formats', () {
      // String format
      var html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "image": "https://example.com/image.jpg"
}
</script>
'''; 
      var document = parse(html);
      var result = SchemaOrgParser.parse(document);
      expect(result!['image'], equals('https://example.com/image.jpg'));

      // Array format
      html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "image": ["https://example.com/image.jpg"]
}
</script>
'''; 
      document = parse(html);
      result = SchemaOrgParser.parse(document);
      expect(result!['image'], equals('https://example.com/image.jpg'));

      // Object format
      html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "image": {"url": "https://example.com/image.jpg"}
}
</script>
'''; 
      document = parse(html);
      result = SchemaOrgParser.parse(document);
      expect(result!['image'], equals('https://example.com/image.jpg'));
    });

    test('handles plain text times', () {
      final html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "prepTime": "20",
  "cookTime": "45"
}
</script>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result!['prepTime'], equals(20));
      expect(result['cookTime'], equals(45));
    });

    test('handles missing fields gracefully', () {
      final html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Minimal"
}
</script>
'''; 
      
      final document = parse(html);
      final result = SchemaOrgParser.parse(document);
      
      expect(result, isNotNull);
      expect(result!['title'], equals('Minimal'));
      expect(result['ingredients'], isEmpty);
      expect(result['instructions'], isEmpty);
    });

    test('parses yield from various formats', () {
      // String with number
      var html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "recipeYield": "8 servings"
}
</script>
'''; 
      var document = parse(html);
      var result = SchemaOrgParser.parse(document);
      expect(result!['servings'], equals(8));

      // Array
      html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Test",
  "recipeYield": ["6 servings"]
}
</script>
'''; 
      document = parse(html);
      result = SchemaOrgParser.parse(document);
      expect(result!['servings'], equals(6));
    });
  });
}
