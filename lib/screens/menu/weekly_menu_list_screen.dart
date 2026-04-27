/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/menu/weekly_menu.dart';
import '../../core/menu/weekly_menu_service.dart';
import '../../repository.dart';
import 'grocery_list_screen.dart';
import 'menu_editor_screen.dart';

/// Screen showing list of weekly menus
class WeeklyMenuListScreen extends StatefulWidget {
  const WeeklyMenuListScreen({super.key});

  @override
  State<WeeklyMenuListScreen> createState() => _WeeklyMenuListScreenState();
}

class _WeeklyMenuListScreenState extends State<WeeklyMenuListScreen> {
  List<WeeklyMenu> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<GitJournalRepo>();
      final menuService = WeeklyMenuService(repoPath: repo.repoPath);
      
      // Load menus without recipes — handle missing recipes gracefully
      final menus = await menuService.loadAllMenus([]);

      setState(() {
        _menus = menus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando menús: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menús Semanales'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenus,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _menus.isEmpty
                ? _buildEmptyState()
                : _buildMenuList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewMenu(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Menú'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_view_week,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay menús semanales',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primer menú para planificar comidas',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewMenu(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Menú'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.calendar_today),
            ),
            title: Text(menu.name),
            subtitle: Text(
              '${menu.filledSlots}/${menu.totalSlots} comidas planificadas',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _viewGroceryList(menu),
                  tooltip: 'Lista de compras',
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _editMenu(menu),
            onLongPress: () => _confirmDeleteMenu(menu),
          ),
        );
      },
    );
  }

  Future<void> _createNewMenu() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NewMenuDialog(),
    );

    if (result != null) {
      final repo = context.read<GitJournalRepo>();
      final menuService = WeeklyMenuService(repoPath: repo.repoPath);
      
      final newMenu = menuService.createNewMenu(name: result);
      await menuService.saveMenu(newMenu);
      
      _loadMenus();
      
      // Navigate to editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuEditorScreen(menu: newMenu),
        ),
      );
    }
  }

  Future<void> _editMenu(WeeklyMenu menu) async {
    // Navigate to editor — full recipe resolution can be added later
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuEditorScreen(menu: menu),
      ),
    ).then((_) => _loadMenus());
  }

  void _viewGroceryList(WeeklyMenu menu) {
    if (menu.allRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega recetas al menú primero'),
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
  }

  Future<void> _confirmDeleteMenu(WeeklyMenu menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Menú'),
        content: Text('¿Eliminar "${menu.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = context.read<GitJournalRepo>();
        final menuService = WeeklyMenuService(repoPath: repo.repoPath);
        await menuService.deleteMenu(menu.id);
        _loadMenus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${menu.name}" eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando menú: $e')),
          );
        }
      }
    }
  }
}

/// Dialog to create a new menu
class _NewMenuDialog extends StatefulWidget {
  @override
  State<_NewMenuDialog> createState() => _NewMenuDialogState();
}

class _NewMenuDialogState extends State<_NewMenuDialog> {
  final _controller = TextEditingController(text: 'Menú Semanal');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Menú Semanal'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nombre del menú',
          hintText: 'Ej: Menú Semanal 1',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
