import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Timer? _pollingTimer;
  static final Set<String> _shownIds = {}; // already shown notifications track

  // ─── INIT ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── SHOW NOTIFICATION ───────────────────────────────────────────────────

  static Future<void> _show(String id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Attendance and leave notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      id.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // ─── START POLLING ───────────────────────────────────────────────────────

  static void startPolling() {
    _pollingTimer?.cancel();

    // Tarat ek vaar check karo
    _checkNewNotifications();

    // Darak 30 seconds ma check karo
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkNewNotifications(),
    );

    debugPrint('Notification polling started');
  }

  // ─── STOP POLLING ────────────────────────────────────────────────────────

  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Notification polling stopped');
  }

  // ─── CHECK NEW NOTIFICATIONS ─────────────────────────────────────────────

  static Future<void> _checkNewNotifications() async {
    try {
      debugPrint("Checking notifications...");

      final data = await ApiService.getNotifications(filter: 'unread');

      debugPrint("API Response = $data");

      final List<dynamic> notifications =
          data['results'] ?? data['notifications'] ?? [];

      debugPrint("Unread Count = ${notifications.length}");

      for (final n in notifications) {
        final String id = n['id']?.toString() ?? '';
        final bool isRead = n['is_read'] ?? false;

        debugPrint(
            "Notification => ID:$id Read:$isRead Title:${n['title']}");

        if (id.isNotEmpty && !isRead && !_shownIds.contains(id)) {
          _shownIds.add(id);

          await _show(
            id,
            n['title'] ?? '',
            n['message'] ?? '',
          );

          debugPrint("LOCAL NOTIFICATION SHOWN");
        }
      }
    } catch (e) {
      debugPrint("Polling error: $e");
    }
  }
  // ─── CLEAR SHOWN IDS (logout vakhte) ─────────────────────────────────────

  static void clearShownIds() {
    _shownIds.clear();
  }
}