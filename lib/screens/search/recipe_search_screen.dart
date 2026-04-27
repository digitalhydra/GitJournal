/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_repository_service.dart';
import '../../repository.dart';
import '../recipe_detail_screen.dart';

/// Search screen for finding recipes by title, ingredients, or tags
class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<GitJournalRepo>();
      final service = RecipeRepositoryService(repoPath: repo.repoPath);
      final recipes = await service.loadAllRecipes();

      setState(() {
        _allRecipes = recipes;
        _filteredRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando recetas: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredRecipes = _filterRecipes(_searchQuery);
    });
  }

  List<Recipe> _filterRecipes(String query) {
    if (query.isEmpty) {
      return _allRecipes;
    }

    return _allRecipes.where((recipe) {
      // Search in title
      if (recipe.title.toLowerCase().contains(query)) {
        return true;
      }

      // Search in ingredients
      for (final ingredient in recipe.ingredients) {
        if (ingredient.name.toLowerCase().contains(query)) {
          return true;
        }
      }

      // Search in tags
      for (final tag in recipe.tags) {
        if (tag.toLowerCase().contains(query)) {
          return true;
        }
      }

      // Search in body/instructions
      if (recipe.body.toLowerCase().contains(query)) {
        return true;
      }

      return false;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar recetas...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128)),
          ),
          style: theme.textTheme.titleLarge,
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildResultsList(),
    );
  }

  Widget _buildResultsList() {
    if (_filteredRecipes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return _RecipeSearchResultCard(
          recipe: recipe,
          searchQuery: _searchQuery,
          onTap: () => _onRecipeTap(recipe),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Escribe para buscar',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Busca por título, ingrediente o etiqueta',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron recetas',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _onRecipeTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}

/// Card displaying a search result with highlighted matches
class _RecipeSearchResultCard extends StatelessWidget {
  final Recipe recipe;
  final String searchQuery;
  final VoidCallback onTap;

  const _RecipeSearchResultCard({
    required this.recipe,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with highlighting
              _HighlightedText(
                text: recipe.title,
                query: searchQuery,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Metadata row
              Row(
                children: [
                  if (recipe.prepTime != null) ...[
                    Icon(Icons.timer, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${recipe.prepTime} min'),
                    const SizedBox(width: 16),
                  ],
                  if (recipe.servings != null) ...[
                    Icon(Icons.people, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${recipe.servings} porciones'),
                  ],
                ],
              ),

              // Matching ingredients
              if (searchQuery.isNotEmpty && _hasMatchingIngredients)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: _getMatchingIngredients()
                        .take(3)
                        .map((ing) => Chip(
                              label: Text(
                                ing.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: theme.colorScheme.primaryContainer,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),

              // Tags
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: recipe.tags.map((tag) {
                    final isMatch = searchQuery.isNotEmpty &&
                        tag.toLowerCase().contains(searchQuery);
                    return Chip(
                      label: Text('#$tag'),
                      backgroundColor: isMatch
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasMatchingIngredients {
    return recipe.ingredients.any(
      (ing) => ing.name.toLowerCase().contains(searchQuery),
    );
  }

  List<dynamic> _getMatchingIngredients() {
    return recipe.ingredients
        .where((ing) => ing.name.toLowerCase().contains(searchQuery))
        .toList();
  }
}

/// Widget that highlights matching text
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style?.copyWith(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
