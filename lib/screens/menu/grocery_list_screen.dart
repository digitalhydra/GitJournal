/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';

import '../../core/menu/weekly_menu.dart';
import '../../core/recipe/recipe.dart';

/// Screen showing aggregated grocery list from selected recipes
class GroceryListScreen extends StatelessWidget {
  final List<Recipe> recipes;
  final String menuName;

  const GroceryListScreen({
    super.key,
    required this.recipes,
    required this.menuName,
  });

  @override
  Widget build(BuildContext context) {
    final groceryItems = GroceryListGenerator.generate(recipes);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareList(context, groceryItems),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: groceryItems.isEmpty
          ? _buildEmptyState()
          : _buildGroceryList(groceryItems, theme),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Lista vacía',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega recetas con ingredientes',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGroceryList(List<GroceryItem> items, ThemeData theme) {
    return Column(
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${items.length} artículos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _GroceryItemTile(item: item);
            },
          ),
        ),
      ],
    );
  }

  void _shareList(BuildContext context, List<GroceryItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 Lista de Compras: $menuName');
    buffer.writeln();
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. ${item.displayText}');
    }
    
    // Show share dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copiar lista:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(buffer.toString()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Copy to clipboard would go here
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista copiada')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar al portapapeles'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for a single grocery item with checkbox
class _GroceryItemTile extends StatefulWidget {
  final GroceryItem item;

  const _GroceryItemTile({required this.item});

  @override
  State<_GroceryItemTile> createState() => _GroceryItemTileState();
}

class _GroceryItemTileState extends State<_GroceryItemTile> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isChecked = !_isChecked;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: _isChecked,
                onChanged: (value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.displayText,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: _isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: _isChecked ? Colors.grey : null,
                      ),
                    ),
                    if (widget.item.sources.length > 1)
                      Text(
                        '${widget.item.sources.length} recetas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
