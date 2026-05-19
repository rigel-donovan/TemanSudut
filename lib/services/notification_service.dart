import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel IDs
  static const _orderChannelId = 'order_notifications';
  static const _financeChannelId = 'finance_notifications';
  static const _systemChannelId = 'system_notifications';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> showOrderNotification({
    required String title,
    required String body,
  }) async {
    if (!await _isEnabled('notif_order')) return;
    await _show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: _orderChannelId,
      channelName: 'Notifikasi Pesanan',
      channelDesc: 'Pemberitahuan pesanan masuk & selesai',
    );
  }

  /// Menampilkan notifikasi keuangan (jika user mengizinkan)
  Future<void> showFinanceNotification({
    required String title,
    required String body,
  }) async {
    if (!await _isEnabled('notif_finance')) return;
    await _show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: _financeChannelId,
      channelName: 'Notifikasi Keuangan',
      channelDesc: 'Pemberitahuan catatan keuangan baru',
    );
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
  }) async {
    if (!await _isEnabled('notif_system')) return;
    await _show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: _systemChannelId,
      channelName: 'Notifikasi Sistem',
      channelDesc: 'Pembaruan & informasi aplikasi',
    );
  }

  Future<bool> _isEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF5D4037),
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
