/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/recipe/recipe.dart';
import '../cook_mode_screen.dart';

/// Screen showing full recipe details
/// Focus: Ingredients and Markdown body (notes/instructions)
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _displayedRecipe;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _displayedRecipe = widget.recipe;
  }

  void _scaleRecipe(double factor) {
    setState(() {
      _currentScale = factor;
      if (factor == 1.0) {
        _displayedRecipe = widget.recipe;
      } else {
        final baseServings = widget.recipe.servings ?? 1;
        final targetServings = (baseServings * factor).round();
        _displayedRecipe = widget.recipe.scaleTo(targetServings);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayedRecipe.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar',
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and metadata header
            _buildHeader(theme),
            
            const SizedBox(height: 24),
            
            // Scaling buttons (if recipe has servings)
            if (widget.recipe.servings != null) ...[
              _buildScalingSection(theme),
              const SizedBox(height: 24),
            ],
            
            // Ingredients section (FOCUS)
            _buildIngredientsSection(theme),
            
            const SizedBox(height: 24),
            
            // Notes/Instructions from markdown body (FOCUS)
            if (_displayedRecipe.body.isNotEmpty) ...[
              _buildBodySection(theme),
              const SizedBox(height: 24),
            ],
            
            // Bottom padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCookMode(),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Modo Cocinar'),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small image if available (optional)
        if (_displayedRecipe.hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _displayedRecipe.imagePath!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Title
        Text(
          _displayedRecipe.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Metadata row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (_displayedRecipe.hasTime)
              _buildMetadataChip(
                Icons.schedule,
                _displayedRecipe.totalTimeDisplay ?? '',
                theme,
              ),
            if (_displayedRecipe.servings != null)
              _buildMetadataChip(
                Icons.people,
                '${_displayedRecipe.servings} porciones',
                theme,
              ),
            if (_displayedRecipe.prepTime != null)
              _buildMetadataChip(
                Icons.timer,
                'Prep: ${_displayedRecipe.prepTime} min',
                theme,
              ),
            if (_displayedRecipe.cookTime != null)
              _buildMetadataChip(
                Icons.local_fire_department,
                'Cocción: ${_displayedRecipe.cookTime} min',
                theme,
              ),
          ],
        ),
        
        // Tags
        if (_displayedRecipe.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _displayedRecipe.tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataChip(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildScalingSection(ThemeData theme) {
    final baseServings = widget.recipe.servings!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildScaleButton(
              '1x',
              baseServings,
              _currentScale == 1.0,
              () => _scaleRecipe(1.0),
              theme,
            ),
            const SizedBox(width: 8),
            _buildScaleButton(
              '2x',
              baseServings * 2,
              _currentScale == 2.0,
              () => _scaleRecipe(2.0),
              theme,
            ),
            const SizedBox(width: 8),
            _buildScaleButton(
              '3x',
              baseServings * 3,
              _currentScale == 3.0,
              () => _scaleRecipe(3.0),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleButton(
    String label,
    int servings,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return ChoiceChip(
      label: Text('$label ($servings)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildIngredientsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_basket,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Ingredientes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_displayedRecipe.ingredients.isEmpty)
          Text(
            'No hay ingredientes listados',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: _displayedRecipe.ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                final isLast = index == _displayedRecipe.ingredients.length - 1;
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fiber_manual_record,
                            size: 8,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ingredient.displayText,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBodySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Instrucciones y Notas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: MarkdownBody(
            data: _displayedRecipe.body,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              h1: theme.textTheme.headlineSmall,
              h2: theme.textTheme.titleLarge,
              h3: theme.textTheme.titleMedium,
              p: theme.textTheme.bodyLarge,
              listBullet: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Receta'),
        content: Text('¿Estás segura de que quieres eliminar "${_displayedRecipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete recipe
              Navigator.pop(context);
              Navigator.pop(context); // Go back to list
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _openCookMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookModeScreen(recipe: _displayedRecipe),
      ),
    );
  }
}
