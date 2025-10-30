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
          return NutritionData.fromOpenFoodFacts(data['product']);
        }
      }
      // Return null if product not found or response status is not 200
      return null;
    } catch (e) {
      // Return null on any exception (e.g., network error)
      print('Error fetching Open Food Facts data: $e');
      return null;
    }
  }
}
