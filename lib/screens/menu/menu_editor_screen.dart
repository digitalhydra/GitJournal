/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/menu/weekly_menu.dart';
import '../../core/menu/weekly_menu_service.dart';
import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_repository_service.dart';
import '../../repository.dart';

/// Screen for editing a weekly menu
/// Shows a grid of days x meals where user can assign recipes
class MenuEditorScreen extends StatefulWidget {
  final WeeklyMenu menu;

  const MenuEditorScreen({
    super.key,
    required this.menu,
  });

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  late WeeklyMenu _menu;
  List<Recipe> _allRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _menu = widget.menu;
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final repo = context.read<GitJournalRepo>();
      final recipeService = RecipeRepositoryService(repoPath: repo.repoPath);
      final recipes = await recipeService.loadAllRecipes();

      setState(() {
        _allRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_menu.name),
            Text(
              '${_menu.filledSlots}/${_menu.totalSlots} comidas',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveMenu(),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMenuGrid(),
    );
  }

  Widget _buildMenuGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type headers
          _buildMealHeaders(),
          const SizedBox(height: 8),
          // Days
          ...DayOfWeek.all.map((day) => _buildDayRow(day)),
        ],
      ),
    );
  }

  Widget _buildMealHeaders() {
    return Row(
      children: [
        // Empty corner cell
        SizedBox(
          width: 80,
          child: Text(
            'Día',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Meal type headers
        ...MealType.all.map((mealType) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Icon(_getMealIcon(mealType), size: 20),
                const SizedBox(height: 4),
                Text(
                  mealType.spanishName,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDayRow(DayOfWeek day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Day name
            SizedBox(
              width: 80,
              child: Text(
                day.spanishName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Meal slots
            ...MealType.all.map((mealType) => Expanded(
              child: _buildMealSlot(day, mealType),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(DayOfWeek day, MealType mealType) {
    final recipe = _menu.getRecipe(day, mealType);
    final hasRecipe = recipe != null;

    return GestureDetector(
      onTap: () => _selectRecipe(day, mealType),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(8),
        height: 60,
        decoration: BoxDecoration(
          color: hasRecipe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasRecipe
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ),
        child: hasRecipe
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : const Center(
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  IconData _getMealIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.coffee;
      case MealType.lunch:
        return Icons.wb_sunny;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  Future<void> _selectRecipe(DayOfWeek day, MealType mealType) async {
    final result = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecipePickerSheet(
        recipes: _allRecipes,
        currentRecipe: _menu.getRecipe(day, mealType),
        day: day,
        mealType: mealType,
      ),
    );

    // Result can be:
    // - Recipe: assign this recipe
    // - null: user cancelled, do nothing
    // - Special "remove" action handled within sheet
    
    if (result != null) {
      setState(() {
        _menu.setRecipe(day, mealType, result);
      });
    }
  }

  Future<void> _saveMenu() async {
    try {
      final repo = context.read<GitJournalRepo>();
      final menuService = WeeklyMenuService(repoPath: repo.repoPath);
      await menuService.saveMenu(_menu);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menú guardado')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }
}

/// Bottom sheet for selecting a recipe
class _RecipePickerSheet extends StatelessWidget {
  final List<Recipe> recipes;
  final Recipe? currentRecipe;
  final DayOfWeek day;
  final MealType mealType;

  const _RecipePickerSheet({
    required this.recipes,
    this.currentRecipe,
    required this.day,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${day.spanishName} - ${mealType.spanishName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (currentRecipe != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Return special value to indicate removal
                        // We'll handle this differently
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Quitar receta',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Recipe list
            Expanded(
              child: recipes.isEmpty
                  ? const Center(
                      child: Text('No hay recetas disponibles'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final isSelected = recipe.id == currentRecipe?.id;
                        
                        return ListTile(
                          leading: recipe.hasImage
                              ? const Icon(Icons.image)
                              : const Icon(Icons.restaurant_menu),
                          title: Text(recipe.title),
                          subtitle: Text(
                            '${recipe.ingredients.length} ingredientes',
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          selected: isSelected,
                          onTap: () {
                            Navigator.pop(context, recipe);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
