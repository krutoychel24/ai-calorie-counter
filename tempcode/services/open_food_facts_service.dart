import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';

class OpenFoodFactsService {
  final String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';

  Future<NutritionData?> getProductByBarcode(String barcode) async {
    final Uri uri = Uri.parse('$_baseUrl$barcode.json?fields=product_name,nutriments,serving_size,ingredients_text');
    
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'NutriScan - Flutter - Version 1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'];

          // Helper to safely parse nutrient values
          double _parseDouble(dynamic value) {
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value) ?? 0.0;
            return 0.0;
          }

          // Open Food Facts provides nutrients per 100g.
          // We will use this as the base, assuming a 100g serving if not specified.
          final servingWeight = _parseDouble(product['serving_size']?.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
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

          List<String> ingredients = product['ingredients_text']?.toString().split(',').map((e) => e.trim()).toList() ?? [];

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
      }
      return null;
    } catch (e) {
      print('Error fetching Open Food Facts data: $e');
      throw Exception('Failed to get product data.');
    }
  }
}
