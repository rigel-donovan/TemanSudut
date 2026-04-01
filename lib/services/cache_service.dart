import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const int ttlHours = 1; // Cache expires after 1 hour
  static const String _keyProducts = 'cache_products';
  static const String _keyCategories = 'cache_categories';
  static const String _suffixTs = '_ts';

  // ─── Internal helpers ───────────────────────────────────────────────────────

  static Future<bool> _isValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(key + _suffixTs);
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < ttlHours * 3600 * 1000;
  }

  static Future<void> _saveJson(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setInt(key + _suffixTs, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<dynamic> _loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>?> getProducts() async {
    if (!await _isValid(_keyProducts)) return null;
    return (await _loadJson(_keyProducts)) as List<dynamic>?;
  }

  static Future<void> saveProducts(List<dynamic> data) =>
      _saveJson(_keyProducts, data);

  static Future<List<dynamic>?> getCategories() async {
    if (!await _isValid(_keyCategories)) return null;
    return (await _loadJson(_keyCategories)) as List<dynamic>?;
  }

  static Future<void> saveCategories(List<dynamic> data) =>
      _saveJson(_keyCategories, data);

  /// Call this to bust cached products (e.g. after an admin product update).
  static Future<void> invalidateProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyProducts + _suffixTs);
  }

  /// Call this to bust all data caches.
  static Future<void> invalidateAll() async {
    await invalidateProducts();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCategories);
    await prefs.remove(_keyCategories + _suffixTs);
  }
}
