/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../recipe/recipe.dart';
import 'weekly_menu.dart';

/// Service for loading and saving weekly menus
class WeeklyMenuService {
  final String repoPath;

  WeeklyMenuService({required this.repoPath});

  String get _menuDirPath => p.join(repoPath, '.recipejournal', 'menus');

  /// Get the menu file path
  String _getMenuFilePath(String menuId) {
    return p.join(_menuDirPath, '$menuId.json');
  }

  /// Load all weekly menus
  Future<List<WeeklyMenu>> loadAllMenus(List<Recipe> allRecipes) async {
    final menus = <WeeklyMenu>[];
    final recipesById = {for (var r in allRecipes) r.id: r};

    try {
      final dir = Directory(_menuDirPath);
      if (!await dir.exists()) {
        return menus;
      }

      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final menu = WeeklyMenu.fromJson(json, recipesById);
            menus.add(menu);
          } catch (e) {
            // Skip invalid menu files
            continue;
          }
        }
      }
    } catch (e) {
      // Return empty list on error
    }

    // Sort by creation date (newest first)
    menus.sort((a, b) => b.created.compareTo(a.created));
    return menus;
  }

  /// Load a specific menu by ID
  Future<WeeklyMenu?> loadMenu(String menuId, List<Recipe> allRecipes) async {
    try {
      final filePath = _getMenuFilePath(menuId);
      final file = File(filePath);
      
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final recipesById = {for (var r in allRecipes) r.id: r};
      
      return WeeklyMenu.fromJson(json, recipesById);
    } catch (e) {
      return null;
    }
  }

  /// Save a weekly menu
  Future<void> saveMenu(WeeklyMenu menu) async {
    final dir = Directory(_menuDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = _getMenuFilePath(menu.id);
    final file = File(filePath);
    final content = jsonEncode(menu.toJson());
    
    await file.writeAsString(content);
  }

  /// Delete a weekly menu
  Future<void> deleteMenu(String menuId) async {
    final filePath = _getMenuFilePath(menuId);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Create a new menu for the current week
  WeeklyMenu createNewMenu({String? name}) {
    final now = DateTime.now();
    // Find Monday of current week
    final daysSinceMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysSinceMonday));
    
    return WeeklyMenu(
      name: name ?? 'Menú Semanal ${_formatDate(monday)}',
      weekStart: DateTime(monday.year, monday.month, monday.day),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
