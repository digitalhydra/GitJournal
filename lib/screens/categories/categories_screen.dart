/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_category.dart';
import '../../core/recipe/recipe_repository_service.dart';
import '../../repository.dart';
import '../../settings/app_config.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/categories/category_card.dart';
import '../editor/recipe_editor_screen.dart';
import '../menu/weekly_menu_list_screen.dart';
import '../recipe_detail_screen.dart';
import '../search/recipe_search_screen.dart';
import 'recipe_list_screen.dart';

/// Main screen showing grid of recipe categories
/// Entry point for browsing recipes
class CategoriesScreen extends StatefulWidget {
  static const routePath = '/';

  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<RecipeCategory> _categories = [];
  List<Recipe> _allRecipes = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

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

      // Store all recipes for favorites filtering
      setState(() {
        _allRecipes = recipes;
      });

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
    final service = RecipeRepositoryService(repoPath: repo.repoPath);
    
    // Create sample recipe if not exists
    await service.createSampleRecipeIfNeeded();
    
    // Load all recipes
    final recipes = await service.loadAllRecipes();
    
    // Filter sample recipe if hidden
    final appConfig = context.read<AppConfig>();
    if (appConfig.sampleRecipeHidden) {
      return recipes.where((r) => r.id != RecipeRepositoryService.sampleRecipeId).toList();
    }
    
    return recipes;
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
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Mis Recetas'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            tooltip: _showFavoritesOnly ? 'Mostrar todas' : 'Mostrar favoritos',
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeSearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            tooltip: 'Menús Semanales',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeeklyMenuListScreen(),
                ),
              );
            },
          ),
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
            : _showFavoritesOnly
                ? _buildFavoritesList()
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

  Widget _buildFavoritesList() {
    final favoriteRecipes = _allRecipes.where((r) => r.isFavorite).toList();

    if (favoriteRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay favoritos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca recetas como favoritas para verlas aquí',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _showFavoritesOnly = false;
                });
              },
              child: const Text('Ver todas las recetas'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: favoriteRecipes.length,
          itemBuilder: (context, index) {
            final recipe = favoriteRecipes[index];
            return RecipeCard(
              recipe: recipe,
              onTap: () => _onRecipeTap(recipe),
            );
          },
        );
      },
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

  void _onRecipeTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    ).then((_) => _loadCategories());
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
                final repo = context.read<GitJournalRepo>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeEditorScreen(
                      repoPath: repo.repoPath,
                    ),
                  ),
                ).then((_) => _loadCategories());
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
