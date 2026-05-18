import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan preferensi notifikasi pengguna secara persisten.
class NotificationPrefsProvider with ChangeNotifier {
  static const _keyOrder = 'notif_order';
  static const _keyFinance = 'notif_finance';
  static const _keySystem = 'notif_system';

  bool orderNotif = true;
  bool financeNotif = false;
  bool systemNotif = true;

  NotificationPrefsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    orderNotif = prefs.getBool(_keyOrder) ?? true;
    financeNotif = prefs.getBool(_keyFinance) ?? false;
    systemNotif = prefs.getBool(_keySystem) ?? true;
    notifyListeners();
  }

  Future<void> save({required bool order, required bool finance, required bool system}) async {
    orderNotif = order;
    financeNotif = finance;
    systemNotif = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOrder, order);
    await prefs.setBool(_keyFinance, finance);
    await prefs.setBool(_keySystem, system);
    notifyListeners();
  }
}
