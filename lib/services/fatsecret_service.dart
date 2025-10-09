import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/food_nutrition.dart';

class FatSecretService {
  static final FatSecretService _instance = FatSecretService._internal();
  factory FatSecretService() => _instance;
  FatSecretService._internal();

  final String _baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  String? _accessToken;
  
  String get _clientId => dotenv.env['FATSECRET_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['FATSECRET_CLIENT_SECRET'] ?? '';

  // Get OAuth 2.0 access token (FatSecret uses OAuth 2.0 Client Credentials flow)
  Future<void> _authenticate() async {
    if (_accessToken != null) return; // Already authenticated

    try {
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await http.post(
        Uri.parse('https://oauth.fatsecret.com/connect/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'scope': 'basic',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        debugPrint('✅ FatSecret authenticated successfully');
      } else {
        debugPrint('❌ FatSecret auth failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to authenticate with FatSecret');
      }
    } catch (e) {
      debugPrint('❌ FatSecret auth error: $e');
      rethrow;
    }
  }

  // Search for food by name
  Future<List<FoodSearchResult>> searchFood(String query) async {
    await _authenticate();

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'foods.search',
        'search_expression': query,
        'format': 'json',
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods']?['food'];
        
        if (foods == null) return [];
        
        final foodList = foods is List ? foods : [foods];
        return foodList.map((f) => FoodSearchResult.fromJson(f)).toList();
      } else {
        debugPrint('❌ Food search failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Food search error: $e');
      return [];
    }
  }

  // Get detailed nutrition info for a specific food
  Future<FoodNutrition?> getFoodNutrition(String foodId) async {
    await _authenticate();

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'food.get.v2',
        'food_id': foodId,
        'format': 'json',
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FoodNutrition.fromJson(data['food']);
      } else {
        debugPrint('❌ Get nutrition failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get nutrition error: $e');
      return null;
    }
  }

  // Quick lookup: Search and get first result's nutrition
  Future<FoodNutrition?> quickNutritionLookup(String foodName) async {
    final results = await searchFood(foodName);
    if (results.isEmpty) return null;
    
    return await getFoodNutrition(results.first.foodId);
  }
}
