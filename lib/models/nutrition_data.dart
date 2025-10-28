import 'dart:convert';

class NutritionData {
  final String dishName;
  final double weight;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final List<String> ingredients;

  NutritionData({
    required this.dishName,
    required this.weight,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.ingredients,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
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
      dishName: json['dish_name']?.toString() ?? 'N/A',
      weight: _parseDouble(json['weight']),
      calories: _parseDouble(json['calories']),
      protein: _parseDouble(json['protein']),
      fat: _parseDouble(json['fat']),
      carbs: _parseDouble(json['carbs']),
      ingredients: ingredientsList,
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
    };
  }
}