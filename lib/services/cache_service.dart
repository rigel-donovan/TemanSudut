import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const int ttlHours = 1;
  static const String _keyProducts = 'cache_products';
  static const String _keyCategories = 'cache_categories';
  static const String _keyMgmtStock = 'cache_mgmt_stock';
  static const String _keyMgmtMaterials = 'cache_mgmt_materials';
  static const String _keyMgmtUsers = 'cache_mgmt_users';
  static const String _suffixTs = '_ts';


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

  /// Call this to bust cached products 
  static Future<void> invalidateProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyProducts + _suffixTs);
  }

  static Future<List<dynamic>?> getMgmtStock() async {
    if (!await _isValid(_keyMgmtStock)) return null;
    return (await _loadJson(_keyMgmtStock)) as List<dynamic>?;
  }

  static Future<void> saveMgmtStock(List<dynamic> data) =>
      _saveJson(_keyMgmtStock, data);

  static Future<List<dynamic>?> getMgmtMaterials() async {
    if (!await _isValid(_keyMgmtMaterials)) return null;
    return (await _loadJson(_keyMgmtMaterials)) as List<dynamic>?;
  }

  static Future<void> saveMgmtMaterials(List<dynamic> data) =>
      _saveJson(_keyMgmtMaterials, data);

  static Future<List<dynamic>?> getMgmtUsers() async {
    if (!await _isValid(_keyMgmtUsers)) return null;
    return (await _loadJson(_keyMgmtUsers)) as List<dynamic>?;
  }

  static Future<void> saveMgmtUsers(List<dynamic> data) =>
      _saveJson(_keyMgmtUsers, data);

  static Future<void> invalidateMgmtUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMgmtUsers);
    await prefs.remove(_keyMgmtUsers + _suffixTs);
  }

  static Future<void> invalidateAll() async {
    await invalidateProducts();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCategories);
    await prefs.remove(_keyCategories + _suffixTs);
    await prefs.remove(_keyMgmtStock);
    await prefs.remove(_keyMgmtStock + _suffixTs);
    await prefs.remove(_keyMgmtMaterials);
    await prefs.remove(_keyMgmtMaterials + _suffixTs);
    await prefs.remove(_keyMgmtUsers);
    await prefs.remove(_keyMgmtUsers + _suffixTs);
  }
}
