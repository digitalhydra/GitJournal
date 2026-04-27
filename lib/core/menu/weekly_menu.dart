/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import '../recipe/recipe.dart';

/// Represents a day of the week
enum DayOfWeek {
  monday('Lunes'),
  tuesday('Martes'),
  wednesday('Miércoles'),
  thursday('Jueves'),
  friday('Viernes'),
  saturday('Sábado'),
  sunday('Domingo');

  final String spanishName;
  const DayOfWeek(this.spanishName);

  static List<DayOfWeek> get all => values;
}

/// Represents a meal type
enum MealType {
  breakfast('Desayuno'),
  lunch('Almuerzo'),
  dinner('Cena'),
  snack('Merienda');

  final String spanishName;
  
  const MealType(this.spanishName);
  
  static List<MealType> get all => values;
}

/// A single meal slot in the weekly menu
class MealSlot {
  final DayOfWeek day;
  final MealType mealType;
  Recipe? recipe;

  MealSlot({
    required this.day,
    required this.mealType,
    this.recipe,
  });

  bool get hasRecipe => recipe != null;
}

/// Weekly menu containing all meal slots
class WeeklyMenu {
  final String id;
  String name;
  DateTime weekStart;
  final Map<DayOfWeek, Map<MealType, Recipe?>> meals;
  DateTime created;
  DateTime modified;

  WeeklyMenu({
    String? id,
    required this.name,
    required this.weekStart,
    Map<DayOfWeek, Map<MealType, Recipe?>>? meals,
    DateTime? created,
    DateTime? modified,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       meals = meals ?? _initializeEmptyMeals(),
       created = created ?? DateTime.now(),
       modified = modified ?? DateTime.now();

  static Map<DayOfWeek, Map<MealType, Recipe?>> _initializeEmptyMeals() {
    final meals = <DayOfWeek, Map<MealType, Recipe?>>{};
    for (final day in DayOfWeek.all) {
      meals[day] = {};
      for (final mealType in MealType.all) {
        meals[day]![mealType] = null;
      }
    }
    return meals;
  }

  /// Set a recipe for a specific day and meal
  void setRecipe(DayOfWeek day, MealType mealType, Recipe? recipe) {
    meals[day]![mealType] = recipe;
    modified = DateTime.now();
  }

  /// Get recipe for a specific slot
  Recipe? getRecipe(DayOfWeek day, MealType mealType) {
    return meals[day]?[mealType];
  }

  /// Check if a slot has a recipe
  bool hasRecipe(DayOfWeek day, MealType mealType) {
    return meals[day]?[mealType] != null;
  }

  /// Get all recipes in the menu (for grocery list)
  List<Recipe> get allRecipes {
    final recipes = <Recipe>{};
    for (final dayMeals in meals.values) {
      for (final recipe in dayMeals.values) {
        if (recipe != null) {
          recipes.add(recipe);
        }
      }
    }
    return recipes.toList();
  }

  /// Count filled slots
  int get filledSlots {
    int count = 0;
    for (final dayMeals in meals.values) {
      for (final recipe in dayMeals.values) {
        if (recipe != null) count++;
      }
    }
    return count;
  }

  /// Total slots
  int get totalSlots => DayOfWeek.all.length * MealType.all.length;

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    final mealsJson = <String, Map<String, String?>>{};
    for (final day in DayOfWeek.all) {
      mealsJson[day.name] = {};
      for (final mealType in MealType.all) {
        final recipe = meals[day]![mealType];
        mealsJson[day.name]![mealType.name] = recipe?.id;
      }
    }

    return {
      'id': id,
      'name': name,
      'weekStart': weekStart.toIso8601String(),
      'meals': mealsJson,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  static WeeklyMenu fromJson(
    Map<String, dynamic> json,
    Map<String, Recipe> recipesById,
  ) {
    final meals = _initializeEmptyMeals();
    
    final mealsJson = json['meals'] as Map<String, dynamic>;
    for (final dayName in mealsJson.keys) {
      final day = DayOfWeek.values.firstWhere((d) => d.name == dayName);
      final dayMeals = mealsJson[dayName] as Map<String, dynamic>;
      
      for (final mealTypeName in dayMeals.keys) {
        final mealType = MealType.values.firstWhere((m) => m.name == mealTypeName);
        final recipeId = dayMeals[mealTypeName] as String?;
        if (recipeId != null && recipesById.containsKey(recipeId)) {
          meals[day]![mealType] = recipesById[recipeId];
        }
      }
    }

    return WeeklyMenu(
      id: json['id'] as String,
      name: json['name'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      meals: meals,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
    );
  }
}

/// Represents an item in the grocery list
class GroceryItem {
  final String name;
  double totalAmount;
  String unit;
  final List<RecipeSource> sources; // Which recipes need this

  GroceryItem({
    required this.name,
    required this.totalAmount,
    required this.unit,
    required this.sources,
  });

  String get displayAmount {
    if (totalAmount == totalAmount.roundToDouble()) {
      return '${totalAmount.toInt()}';
    }
    return totalAmount.toStringAsFixed(1);
  }

  String get displayText => '$displayAmount $unit $name';
}

/// Source of a grocery item (which recipe and how much)
class RecipeSource {
  final String recipeName;
  final double amount;
  final String unit;

  RecipeSource({
    required this.recipeName,
    required this.amount,
    required this.unit,
  });
}

/// Generator for grocery lists from weekly menus
class GroceryListGenerator {
  /// Generate aggregated grocery list from multiple recipes
  static List<GroceryItem> generate(List<Recipe> recipes) {
    final ingredientMap = <String, GroceryItem>{};

    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final key = '${ingredient.name.toLowerCase()}_${ingredient.unit.toLowerCase()}';
        
        if (ingredientMap.containsKey(key)) {
          // Aggregate with existing
          final existing = ingredientMap[key]!;
          existing.totalAmount += ingredient.amount;
          existing.sources.add(RecipeSource(
            recipeName: recipe.title,
            amount: ingredient.amount,
            unit: ingredient.unit,
          ));
        } else {
          // Create new entry
          ingredientMap[key] = GroceryItem(
            name: ingredient.name,
            totalAmount: ingredient.amount,
            unit: ingredient.unit,
            sources: [
              RecipeSource(
                recipeName: recipe.title,
                amount: ingredient.amount,
                unit: ingredient.unit,
              ),
            ],
          );
        }
      }
    }

    // Convert to list and sort alphabetically
    final items = ingredientMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return items;
  }
}
