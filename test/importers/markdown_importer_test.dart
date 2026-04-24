/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/importers/markdown_importer.dart';

void main() {
  group('MarkdownImporter', () {
    late MarkdownImporter importer;

    setUp(() {
      importer = MarkdownImporter();
    });

    test('detects markdown with frontmatter', () {
      expect(importer.canHandle('---\ntitle: Test\n---\n'), isTrue);
      expect(importer.canHandle('# Just Markdown'), isTrue);
      expect(importer.canHandle('recipe.md'), isTrue);
    });

    test('parses frontmatter with ingredients', () async {
      final markdown = '''
---
title: Pancakes
prep_time: 10
cook_time: 15
servings: 4
ingredients:
  - name: flour
    amount: 2
    unit: cups
    ml: 500
  - name: eggs
    amount: 2
    unit: ""
---

## Instructions

Mix and cook.
'''; 
      
      final result = await importer.import(markdown);
      
      expect(result.success, isTrue);
      expect(result.title, equals('Pancakes'));
      expect(result.prepTime, equals(10));
      expect(result.cookTime, equals(15));
      expect(result.servings, equals(4));
      expect(result.ingredients, hasLength(2));
      expect(result.ingredients[0].name, equals('flour'));
      expect(result.ingredients[0].amount, equals(2));
    });

    test('parses frontmatter with text ingredients', () async {
      final markdown = '''
---
title: Salad
ingredients:
  - "2 cups lettuce"
  - "1 tomato"
---

Mix together.
'''; 
      
      final result = await importer.import(markdown);
      
      expect(result.ingredients, hasLength(2));
      expect(result.ingredients[0].name, equals('lettuce'));
    });

    test('parses headers without frontmatter', () async {
      final markdown = '''
# Simple Recipe

## Ingredients

- 2 cups flour
- 1 egg

## Instructions

1. Mix ingredients
2. Bake
'''; 
      
      final result = await importer.import(markdown);
      
      expect(result.title, equals('Simple Recipe'));
      expect(result.ingredients, hasLength(2));
      expect(result.instructions, hasLength(2));
    });

    test('detects missing fields', () async {
      final markdown = '''
---
title: Incomplete
---
'''; 
      
      final result = await importer.import(markdown);
      
      expect(result.isPartial, isTrue);
      expect(result.missingFields.contains('ingredients'), isTrue);
      expect(result.missingFields.contains('instructions'), isTrue);
      expect(result.missingFields.contains('time'), isTrue);
    });

    test('handles empty markdown', () async {
      final result = await importer.import('');
      
      expect(result.success, isFalse);
    });

    test('handles markdown without headers', () async {
      final markdown = 'Just some text without structure';
      
      final result = await importer.import(markdown);
      
      expect(result.isPartial, isTrue);
      expect(result.missingFields.contains('ingredients'), isTrue);
    });

    test('parses different instruction headers', () async {
      for (final header in ['Instructions', 'Directions', 'Steps']) {
        final markdown = '''
# Recipe

## Ingredients

- 1 cup flour

## $header

Step one.
'''; 
        
        final result = await importer.import(markdown);
        expect(result.instructions, isNotEmpty, reason: 'Failed for header: $header');
      }
    });
  });
}
