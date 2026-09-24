import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const _key = 'app_locale';

  Locale _locale = const Locale('id');
  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'id';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    notifyListeners();
  }
}
