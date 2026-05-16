// lib/providers/app_settings_provider.dart
// Provider untuk Dark Mode dan Notifikasi — shared ke seluruh app

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  // Plugin notifikasi lokal
  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notifInitialized = false;

  // ===== INISIALISASI PLUGIN NOTIFIKASI =====
  Future<void> initNotifications() async {
    if (_notifInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifPlugin.initialize(initSettings);
    _notifInitialized = true;
  }

  // ===== TOGGLE DARK MODE =====
  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // ===== TOGGLE NOTIFIKASI =====
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();

    if (value) {
      // Kirim notifikasi test saat diaktifkan
      await _showTestNotification();
    }
  }

  // ===== TAMPILKAN NOTIFIKASI TEST =====
  Future<void> _showTestNotification() async {
    if (!_notifInitialized) await initNotifications();

    const androidDetails = AndroidNotificationDetails(
      'medi_help_channel',
      'MediHelp Notifications',
      channelDescription: 'Notifikasi dari aplikasi MediHelp',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _notifPlugin.show(
      0,
      'Notifikasi Aktif ✅',
      'Notifikasi MediHelp telah diaktifkan.',
      notifDetails,
    );
  }

  // ===== KIRIM NOTIFIKASI REMINDER OBAT =====
  Future<void> showMedicationReminder(String medicationName) async {
    if (!_notificationsEnabled) return;
    if (!_notifInitialized) await initNotifications();

    const androidDetails = AndroidNotificationDetails(
      'medi_help_reminder',
      'Reminder Obat',
      channelDescription: 'Pengingat minum obat',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notifPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '💊 Waktunya Minum Obat',
      'Jangan lupa minum $medicationName',
      const NotificationDetails(android: androidDetails),
    );
  }
}