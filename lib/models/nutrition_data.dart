import 'dart:convert';

class NutritionData {
  final String? id;
  final String dishName;
  final double weight;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final List<String> ingredients;
  final double usefulness;

  NutritionData({
    this.id,
    required this.dishName,
    required this.weight,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.ingredients,
    required this.usefulness,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json, {String? id}) {
    var ingredientsFromJson = json['ingredients'];
    List<String> ingredientsList = [];
    if (ingredientsFromJson is List) {
       ingredientsList = ingredientsFromJson.map((item) => item.toString()).toList();
    }

    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return NutritionData(
      id: id ?? json['id'] as String?,
      dishName: json['dishName']?.toString() ?? json['dish_name']?.toString() ?? 'N/A',
      weight: _parseDouble(json['weight']),
      calories: _parseDouble(json['calories']),
      protein: _parseDouble(json['protein']),
      fat: _parseDouble(json['fat']),
      carbs: _parseDouble(json['carbs']),
      ingredients: ingredientsList,
      usefulness: _parseDouble(json['usefulness']),
    );
  }

  factory NutritionData.fromOpenFoodFacts(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Open Food Facts provides nutrients per 100g.
    // We will use this as the base, assuming a 100g serving if not specified.
    final servingSizeString = product['serving_size']?.toString() ?? '';
    final servingWeight = _parseDouble(servingSizeString.replaceAll(RegExp(r'[^0-9.]'), ''));
    final weight = servingWeight > 0 ? servingWeight : 100.0;

    final caloriesPer100g = _parseDouble(nutriments['energy-kcal_100g']);
    final proteinPer100g = _parseDouble(nutriments['proteins_100g']);
    final carbsPer100g = _parseDouble(nutriments['carbohydrates_100g']);
    final fatPer100g = _parseDouble(nutriments['fat_100g']);

    // Calculate nutrients for the given serving size
    final calories = (caloriesPer100g / 100.0) * weight;
    final protein = (proteinPer100g / 100.0) * weight;
    final carbs = (carbsPer100g / 100.0) * weight;
    final fat = (fatPer100g / 100.0) * weight;

    List<String> ingredients = product['ingredients_text']
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    return NutritionData(
      dishName: product['product_name']?.toString() ?? 'Unknown Product',
      weight: weight,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      ingredients: ingredients,
      usefulness: 0.0, // Default to 0.0 as this data is not from AI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dish_name': dishName,
      'weight': weight,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'ingredients': ingredients,
      'usefulness': usefulness,
    };
  }
}