/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/importers/markdown_importer.dart';
import 'package:gitjournal/importers/recipe_importer.dart';

void main() {
  group('MarkdownImporter canHandle', () {
    test('detects markdown with frontmatter', () {
      const markdown = '''---
title: Pasta Carbonara
---

# Instructions

1. Boil pasta
2. Mix eggs and cheese
'''
      ;

      final importer = MarkdownImporter();
      expect(importer.canHandle(markdown), isTrue);
    });

    test('detects markdown with headers', () {
      const markdown = '''# Pasta Carbonara

## Ingredients
- 2 cups pasta
- 3 eggs

## Instructions
1. Boil pasta
2. Mix ingredients
'''
      ;

      final importer = MarkdownImporter();
      expect(importer.canHandle(markdown), isTrue);
    });

    test('detects markdown file extension', () {
      final importer = MarkdownImporter();
      expect(importer.canHandle('recipe.md'), isTrue);
      expect(importer.canHandle('recipe.markdown'), isTrue);
    });

    test('rejects plain text without markdown markers', () {
      final importer = MarkdownImporter();
      expect(importer.canHandle('Just some plain text'), isFalse);
      expect(importer.canHandle('https://example.com/recipe'), isFalse);
    });
  });

  group('MarkdownImporter Spanish', () {
    test('parses Spanish markdown with frontmatter', () async {
      const markdown = '''---
title: Tortilla Española
ingredients:
  - 4 huevos
  - 2 patatas
  - 1 cebolla
prep_time: 15
cook_time: 30
servings: 4
---

# Instrucciones

1. Cortar las patatas
2. Freír las patatas
3. Batir los huevos
4. Mezclar todo
'''
      ;

      final importer = MarkdownImporter();
      final result = await importer.import(markdown);

      expect(result.success, isTrue);
      expect(result.title, equals('Tortilla Española'));
      expect(result.ingredients.length, equals(3));
      expect(result.instructions.length, equals(4));
      expect(result.prepTime, equals(15));
      expect(result.cookTime, equals(30));
      expect(result.servings, equals(4));
    });

    test('parses Spanish markdown with headers', () async {
      const markdown = '''# Gazpacho Andaluz

## Ingredientes
- 1 kg tomates
- 1 pepino
- 1 pimiento verde
- 2 dientes ajo
- 100 ml aceite oliva

## Preparación
1. Lavar las verduras
2. Trocear los tomates
3. Batir todo
4. Añadir aceite
'''
      ;

      final importer = MarkdownImporter();
      final result = await importer.import(markdown);

      expect(result.success, isTrue);
      expect(result.title, equals('Gazpacho Andaluz'));
      expect(result.ingredients.length, equals(5));
      expect(result.instructions.length, equals(4));
    });
  });

  group('MarkdownImporter AI-parsed format', () {
    test('parses AI-generated markdown with full frontmatter', () async {
      const markdown = '''---
id: "a1b2c3d4"
title: "Paella Valenciana"
tags: [cena, española, arroz]
prep_time: 20
cook_time: 40
servings: 6
difficulty: "media"
ingredients:
  - name: "arroz bomba"
    amount: 500
    unit: "g"
    ml: 500
  - name: "pollo"
    amount: 400
    unit: "g"
  - name: "agua"
    amount: 1.5
    unit: "l"
---

# Instrucciones

1. Sofreír el pollo
2. Añadir el arroz
3. Verter el agua caliente
4. Cocinar 20 minutos a fuego lento

# Notas

Usar paellera tradicional si es posible.
'''
      ;

      final importer = MarkdownImporter();
      final result = await importer.import(markdown);

      expect(result.success, isTrue);
      expect(result.title, equals('Paella Valenciana'));
      expect(result.ingredients.length, equals(3));
      expect(result.prepTime, equals(20));
      expect(result.cookTime, equals(40));
      expect(result.servings, equals(6));
    });
  });
}
