import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_ingredient.dart';

class IngredientStorage {
  static const String _key = 'product_ingredients';

  /// Get all ingredients for a specific product
  static Future<List<ProductIngredient>> getIngredients(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final Map<String, dynamic> allData = jsonDecode(raw);
    final key = productId.toString();
    if (!allData.containsKey(key)) return [];

    final List<dynamic> list = allData[key];
    return list.map((e) => ProductIngredient.fromJson(e)).toList();
  }

  static Future<void> saveIngredients(int productId, List<ProductIngredient> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> allData = raw != null ? jsonDecode(raw) : {};

    allData[productId.toString()] = ingredients.map((e) => e.toJson()).toList();

    await prefs.setString(_key, jsonEncode(allData));
  }

  static Future<Map<int, List<ProductIngredient>>> getAllMappings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};

    final Map<String, dynamic> allData = jsonDecode(raw);
    final Map<int, List<ProductIngredient>> result = {};

    allData.forEach((key, value) {
      final productId = int.tryParse(key);
      if (productId != null && value is List) {
        result[productId] = value.map((e) => ProductIngredient.fromJson(e)).toList();
      }
    });

    return result;
  }

  static Future<bool> hasIngredients(int productId) async {
    final ingredients = await getIngredients(productId);
    return ingredients.isNotEmpty;
  }
}
