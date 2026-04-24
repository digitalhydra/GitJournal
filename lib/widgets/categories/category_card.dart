/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import '../../core/recipe/recipe_category.dart';

/// Card widget for displaying a recipe category in the grid
class CategoryCard extends StatelessWidget {
  final RecipeCategory category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or image
              _buildIcon(context),
              const SizedBox(height: 12),
              // Category name
              Text(
                category.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Recipe count
              Text(
                '${category.recipeCount} ${_getRecipeText(category.recipeCount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    // If we have an image from a recipe, show it
    if (category.imagePath != null && category.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          category.imagePath!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildEmojiIcon(context);
          },
        ),
      );
    }
    
    // Otherwise show emoji
    return _buildEmojiIcon(context);
  }

  Widget _buildEmojiIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  String _getRecipeText(int count) {
    if (count == 1) return 'receta';
    return 'recetas';
  }
}
