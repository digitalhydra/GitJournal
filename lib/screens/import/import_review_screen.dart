/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';

import '../../core/ingredients/ingredient.dart';
import '../../core/ingredients/ingredient_parser.dart';
import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_category.dart';
import '../../core/recipe/recipe_repository_service.dart';
import '../../importers/markdown_importer.dart';
import '../../importers/recipe_importer.dart';
import '../../importers/tiktok_importer.dart';
import '../../importers/url_importer.dart';

/// Screen for reviewing and editing imported recipes before saving
/// Shows loading state while extracting, then allows editing title, ingredients, etc.
class ImportReviewScreen extends StatefulWidget {
  final String? sourceUrl;
  final String? markdownContent;
  final String repoPath;

  const ImportReviewScreen({
    super.key,
    this.sourceUrl,
    this.markdownContent,
    required this.repoPath,
  }) : assert(sourceUrl != null || markdownContent != null,
           'Either sourceUrl or markdownContent must be provided');

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  bool _isLoading = true;
  String? _error;

  // Editing controllers
  late TextEditingController _titleController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  late TextEditingController _notesController;
  
  int? _prepTime;
  int? _cookTime;
  int? _servings;
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _ingredientsController = TextEditingController();
    _instructionsController = TextEditingController();
    _notesController = TextEditingController();
    _importRecipe();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _importRecipe() async {
    try {
      ImportResult result;

      if (widget.markdownContent != null) {
        // Import from markdown content (AI-parsed, etc.)
        final importer = MarkdownImporter();
        result = await importer.import(widget.markdownContent!);
      } else if (widget.sourceUrl != null) {
        // Import from URL (TikTok, etc.)
        final importer = _getImporterForUrl(widget.sourceUrl!);
        result = await importer.import(widget.sourceUrl!);
      } else {
        throw StateError('No source URL or markdown content provided');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (result.success) {
          _titleController.text = result.title ?? '';
          _ingredientsController.text = result.ingredients
              .map((i) => i.displayText)
              .join('\n');
          _instructionsController.text = result.instructions.join('\n\n');
          _notesController.text = result.description ?? '';
          _prepTime = result.prepTime;
          _cookTime = result.cookTime;
          _servings = result.servings;
        } else {
          _error = result.error ?? 'Error al importar la receta';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  RecipeImporter _getImporterForUrl(String url) {
    final tiktok = TikTokImporter();
    if (tiktok.canHandle(url)) {
      return tiktok;
    }
    return UrlImporter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Importación'),
        actions: [
          if (!_isLoading && _error == null)
            TextButton(
              onPressed: _saveRecipe,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Extrayendo receta...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al importar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source info (URL or Markdown)
          if (widget.sourceUrl != null) ...[
            Text(
              'Fuente:',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.sourceUrl!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (widget.markdownContent != null) ...[
            Text(
              'Fuente:',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Contenido Markdown (AI/Externo)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Categories/Tags
          Text(
            'Categorías',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: defaultCategories.map((cat) {
              final isSelected = _selectedTags.contains(cat.id);
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(cat.id);
                    } else {
                      _selectedTags.remove(cat.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Time and servings
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Tiempo Prep (min)',
                  _prepTime?.toString() ?? '',
                  (value) => _prepTime = int.tryParse(value),
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  'Tiempo Cocción (min)',
                  _cookTime?.toString() ?? '',
                  (value) => _cookTime = int.tryParse(value),
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  'Porciones',
                  _servings?.toString() ?? '',
                  (value) => _servings = int.tryParse(value),
                  Icons.people,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ingredients
          Text(
            'Ingredientes (uno por línea)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ingredientsController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '2 tazas harina\n1 cucharada azúcar\n3 huevos',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Text(
            'Instrucciones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionsController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paso 1: Mezclar los ingredientes secos...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Notes
          Text(
            'Notas Adicionales',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tips, variaciones, notas...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String initialValue,
    Function(String) onChanged,
    IconData icon,
  ) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, size: 20),
      ),
      onChanged: onChanged,
    );
  }

  Future<void> _saveRecipe() async {
    setState(() => _isLoading = true);

    try {
      // Parse ingredients from text lines
      final ingredientParser = IngredientParser();
      final ingredients = <Ingredient>[];
      
      final ingredientLines = _ingredientsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      for (final line in ingredientLines) {
        final parsed = ingredientParser.tryParse(line.trim());
        if (parsed != null) {
          ingredients.add(parsed);
        }
      }

      // Build body from instructions + notes
      final bodyParts = <String>[];
      if (_instructionsController.text.trim().isNotEmpty) {
        bodyParts.add('# Instrucciones\n\n${_instructionsController.text}');
      }
      if (_notesController.text.trim().isNotEmpty) {
        bodyParts.add('# Notas\n\n${_notesController.text}');
      }

      // Create final recipe
      final recipe = Recipe(
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Receta Importada',
        ingredients: ingredients,
        body: bodyParts.join('\n\n'),
        tags: _selectedTags,
        prepTime: _prepTime,
        cookTime: _cookTime,
        servings: _servings,
      );

      // Save to repository
      final repoService = RecipeRepositoryService(repoPath: widget.repoPath);
      await repoService.saveRecipe(recipe);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receta guardada')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
