/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:gitjournal/utils/decimal_formatter.dart';

/// Represents a recipe ingredient with amount, unit, and name
/// Stores both original values and milliliter conversion
class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final double? milliliters;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.milliliters,
  });

  /// Whether this ingredient has a milliliter conversion
  bool get hasConversion => milliliters != null;

  /// Display text with original measurement
  /// Example: "2 1/2 cups"
  String get amountDisplay {
    return DecimalFormatter.format(amount);
  }

  /// Full display text with inline ml conversion
  /// Example: "2 1/2 cups flour (500ml)" or "3 eggs"
  String get displayText {
    final base = unit.isEmpty 
        ? '$amountDisplay $name'
        : '$amountDisplay $unit $name';
    if (hasConversion) {
      final ml = milliliters!.round();
      return '$base (${ml}ml)';
    }
    return base;
  }

  /// Short display without ml conversion
  /// Example: "2 1/2 cups flour" or "3 eggs"
  String get shortDisplay {
    return unit.isEmpty 
        ? '$amountDisplay $name'
        : '$amountDisplay $unit $name';
  }

  /// Creates a copy with modified fields
  Ingredient copyWith({
    String? name,
    double? amount,
    String? unit,
    double? milliliters,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      milliliters: milliliters ?? this.milliliters,
    );
  }

  /// Scales the ingredient by a factor
  /// Used when scaling recipes (2x, 3x servings)
  Ingredient scale(double factor) {
    final newAmount = amount * factor;
    final newMl = milliliters != null ? milliliters! * factor : null;
    
    return copyWith(
      amount: newAmount,
      milliliters: newMl,
    );
  }

  /// Converts to YAML map for serialization
  Map<String, dynamic> toYaml() {
    final map = <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
    };
    if (milliliters != null) {
      map['ml'] = milliliters;
    }
    return map;
  }

  /// Creates from YAML map
  factory Ingredient.fromYaml(Map<String, dynamic> yaml) {
    return Ingredient(
      name: yaml['name'] as String,
      amount: (yaml['amount'] as num).toDouble(),
      unit: yaml['unit'] as String,
      milliliters: yaml['ml'] != null ? (yaml['ml'] as num).toDouble() : null,
    );
  }

  @override
  String toString() => 'Ingredient($displayText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.name == name &&
        other.amount == amount &&
        other.unit == unit &&
        other.milliliters == milliliters;
  }

  @override
  int get hashCode => Object.hash(name, amount, unit, milliliters);
}
