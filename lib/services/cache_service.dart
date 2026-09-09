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

  static Future<String> _k(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getInt('active_branch_id') ?? 1;
    return '${baseKey}_b$branchId';
  }

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
    final k = await _k(_keyProducts);
    if (!await _isValid(k)) return null;
    return (await _loadJson(k)) as List<dynamic>?;
  }

  static Future<void> saveProducts(List<dynamic> data) async =>
      _saveJson(await _k(_keyProducts), data);

  static Future<List<dynamic>?> getCategories() async {
    final k = await _k(_keyCategories);
    if (!await _isValid(k)) return null;
    return (await _loadJson(k)) as List<dynamic>?;
  }

  static Future<void> saveCategories(List<dynamic> data) async =>
      _saveJson(await _k(_keyCategories), data);

  /// Call this to bust cached products 
  static Future<void> invalidateProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final k = await _k(_keyProducts);
    await prefs.remove(k);
    await prefs.remove(k + _suffixTs);
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyProducts + _suffixTs);
  }

  static Future<List<dynamic>?> getMgmtStock() async {
    final k = await _k(_keyMgmtStock);
    if (!await _isValid(k)) return null;
    return (await _loadJson(k)) as List<dynamic>?;
  }

  static Future<void> saveMgmtStock(List<dynamic> data) async =>
      _saveJson(await _k(_keyMgmtStock), data);

  static Future<List<dynamic>?> getMgmtMaterials() async {
    final k = await _k(_keyMgmtMaterials);
    if (!await _isValid(k)) return null;
    return (await _loadJson(k)) as List<dynamic>?;
  }

  static Future<void> saveMgmtMaterials(List<dynamic> data) async =>
      _saveJson(await _k(_keyMgmtMaterials), data);

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
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
  }

  // ---- Finance Custom Allocations ----
  static const String _keyFinanceAllocations = 'finance_allocations';
  
  static Future<dynamic> getFinanceAllocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFinanceAllocations);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<void> saveFinanceAllocations(dynamic allocations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFinanceAllocations, jsonEncode(allocations));
  }
}
