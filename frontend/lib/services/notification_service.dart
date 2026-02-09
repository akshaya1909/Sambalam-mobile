import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // 2) Local notifications init
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
    // Ask for notification permission (especially iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);
  }

  // static Future<void> _sendTokenToBackend(String token) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getString('userId'); // store this at login
  //   if (userId == null) return;

  //   // Call backend endpoint to save token
  //   const baseUrl = 'http://192.168.1.13:5000';
  //   await http.post(
  //     Uri.parse('$baseUrl/api/users/$userId/fcm-token'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'token': token, 'platform': Platform.operatingSystem}),
  //   );
  // }

  static Future<void> registerFcmToken() async {
    // 1) Ask permission (mainly iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Get FCM token
    final token = await _messaging.getToken();
    if (token == null) return;

    // 3) Send to backend
    await _sendTokenToBackend(token);

    // 4) Listen for token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); // must be stored at login

    if (userId == null) return;
    // Call backend endpoint to save token
    const baseUrl = 'https://sambalam.ifoxclicks.com';

    final platform = kIsWeb ? 'web' : Platform.operatingSystem;

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users/$userId/fcm-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        // 'platform': Platform.operatingSystem, // 'android', 'ios', etc.
        'platform': platform,
      }),
    );

    // Optional: handle errors/logging
    if (response.statusCode != 200) {
      print(
          'Failed to save FCM token: ${response.statusCode} ${response.body}');
    } else {
      print('FCM token saved for $userId');
    }
  }

  Future<void> scheduleDailyAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'attendance_alarms',
      'Attendance alarms',
      channelDescription: 'Daily punch in/out reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(first, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
