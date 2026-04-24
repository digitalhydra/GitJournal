/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_category.dart';
import '../../repository.dart';
import '../../widgets/categories/category_card.dart';
import 'recipe_list_screen.dart';

/// Main screen showing grid of recipe categories
/// Entry point for browsing recipes
class CategoriesScreen extends StatefulWidget {
  static const routePath = '/categories';

  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<RecipeCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      // Get repository from context
      final repo = context.read<GitJournalRepo>();
      
      // Load all recipes from Git repo
      final recipes = await _loadRecipesFromRepo(repo);
      
      // Calculate recipe counts and images for each category
      final categoriesWithCounts = _calculateCategoryData(recipes);
      
      // Filter out empty categories
      final activeCategories = getActiveCategories(categoriesWithCounts);
      
      setState(() {
        _categories = activeCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando recetas: $e')),
        );
      }
    }
  }

  Future<List<Recipe>> _loadRecipesFromRepo(GitJournalRepo repo) async {
    // TODO: Implement actual recipe loading from Git repo
    // For now return empty list
    return [];
  }

  List<RecipeCategory> _calculateCategoryData(List<Recipe> recipes) {
    return defaultCategories.map((category) {
      // Find recipes matching this category
      final matchingRecipes = recipes.where((recipe) {
        return category.matchesTags(recipe.tags);
      }).toList();
      
      // Get random image from first matching recipe
      String? imagePath;
      for (final recipe in matchingRecipes) {
        if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty) {
          imagePath = recipe.imagePath;
          break;
        }
      }
      
      return category.copyWith(
        recipeCount: matchingRecipes.length,
        imagePath: imagePath,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? _buildEmptyState()
                : _buildCategoryGrid(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add recipe screen
          _showAddRecipeOptions();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Receta'),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate columns based on width
        final columns = constraints.maxWidth > 600 ? 3 : 2;
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return CategoryCard(
              category: category,
              onTap: () => _onCategoryTap(category),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay recetas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primera receta para comenzar',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddRecipeOptions(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Receta'),
          ),
        ],
      ),
    );
  }

  void _onCategoryTap(RecipeCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeListScreen(category: category),
      ),
    );
  }

  void _showAddRecipeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Escribir manualmente'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to recipe editor
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Importar de URL'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to URL import
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Importar de TikTok'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to TikTok import
              },
            ),
          ],
        ),
      ),
    );
  }
}
