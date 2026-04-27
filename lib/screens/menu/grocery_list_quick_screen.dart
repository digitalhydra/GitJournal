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
import 'grocery_list_screen.dart';

/// Screen showing quick access to grocery list
/// Can select from existing menus or create empty list
class GroceryListQuickScreen extends StatefulWidget {
  const GroceryListQuickScreen({super.key});

  @override
  State<GroceryListQuickScreen> createState() => _GroceryListQuickScreenState();
}

class _GroceryListQuickScreenState extends State<GroceryListQuickScreen> {
  List<WeeklyMenu> _menus = [];
  List<Recipe> _allRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<GitJournalRepo>();
      final menuService = WeeklyMenuService(repoPath: repo.repoPath);
      final recipeService = RecipeRepositoryService(repoPath: repo.repoPath);

      final menus = await menuService.loadAllMenus([]);
      final recipes = await recipeService.loadAllRecipes();

      setState(() {
        _menus = menus;
        _allRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section: From Weekly Menus
        if (_menus.isNotEmpty) ...[
          Text(
            'Desde Menús Semanales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._menus.map((menu) => Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(menu.name),
              subtitle: Text(
                '${menu.filledSlots} comidas planificadas',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                if (menu.allRecipes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este menú no tiene recetas'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroceryListScreen(
                      recipes: menu.allRecipes,
                      menuName: menu.name,
                    ),
                  ),
                );
              },
            ),
          )),
          const SizedBox(height: 24),
        ],

        // Section: From All Recipes
        Text(
          'Desde Todas las Recetas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Todas las recetas'),
            subtitle: Text('${_allRecipes.length} recetas'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              if (_allRecipes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay recetas guardadas'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroceryListScreen(
                    recipes: _allRecipes,
                    menuName: 'Todas las Recetas',
                  ),
                ),
              );
            },
          ),
        ),

        // Section: Select Individual Recipes
        const SizedBox(height: 24),
        Text(
          'Seleccionar Recetas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Elegir recetas individuales'),
            subtitle: const Text('Selecciona las recetas para la lista'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _showRecipePicker(),
          ),
        ),
      ],
    );
  }

  void _showRecipePicker() {
    final selectedRecipes = <Recipe>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
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
                            'Seleccionar Recetas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${selectedRecipes.length} seleccionadas',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Recipe list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _allRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _allRecipes[index];
                          final isSelected = selectedRecipes.contains(recipe);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedRecipes.add(recipe);
                                } else {
                                  selectedRecipes.remove(recipe);
                                }
                              });
                            },
                            title: Text(recipe.title),
                            subtitle: Text(
                              '${recipe.ingredients.length} ingredientes',
                            ),
                            secondary: recipe.hasImage
                                ? const Icon(Icons.image)
                                : const Icon(Icons.restaurant_menu),
                          );
                        },
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: selectedRecipes.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroceryListScreen(
                                            recipes: selectedRecipes.toList(),
                                            menuName: 'Selección Personalizada',
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                'Generar Lista (${selectedRecipes.length})',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
