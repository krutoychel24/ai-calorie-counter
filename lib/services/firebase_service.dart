import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';

class FirebaseService {
  static const String _functionUrl = 
      'https://us-central1-calorie-counter-app-bf67e.cloudfunctions.net/analyzeImage';

  Future<NutritionData> analyzeImage(File imageFile, String? additionalInfo, String languageCode) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      final requestBody = {
        'imageBase64': base64Image,
        'mimeType': mimeType,
        'languageCode': languageCode,
        // The 'additionalInfo' is now handled by the backend prompt, but we could pass it if needed.
      };

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));


      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final nutritionData = NutritionData.fromJson(data);
          return nutritionData;
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Server error: ${response.statusCode}');
        } catch (e) {
          throw Exception('Server error ${response.statusCode}: ${response.body}');
        }
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }
}