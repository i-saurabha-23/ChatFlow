import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:interview/firebase_options.dart';

const AndroidNotificationChannel _chatMessagesChannel =
    AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for incoming chat messages.',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Map<String, dynamic>? _pendingTapPayload;
  Future<void> Function(Map<String, dynamic>)? _tapHandler;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _configureLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _dispatchTapPayload(message.data),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _dispatchTapPayload(initialMessage.data);
    }

    _initialized = true;
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  void setNotificationTapHandler(
    Future<void> Function(Map<String, dynamic>) handler,
  ) {
    _tapHandler = handler;
    consumePendingTap();
  }

  void clearNotificationTapHandler() {
    _tapHandler = null;
  }

  Future<void> consumePendingTap() async {
    if (_pendingTapPayload == null) {
      return;
    }

    final payload = Map<String, dynamic>.from(_pendingTapPayload!);
    _pendingTapPayload = null;
    await _dispatchTapPayload(payload);
  }

  Future<void> _configureLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _dispatchTapPayload(decoded);
          }
        } catch (_) {
          // Ignore malformed payload.
        }
      },
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidNotifications?.createNotificationChannel(_chatMessagesChannel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kIsWeb) {
      return;
    }

    final notification = message.notification;
    final data = message.data;

    final title =
        notification?.title ?? data['senderName']?.toString() ?? 'New message';
    final body = notification?.body ?? data['content']?.toString() ?? '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chatMessagesChannel.id,
          _chatMessagesChannel.name,
          channelDescription: _chatMessagesChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> _dispatchTapPayload(Map<String, dynamic> payload) async {
    if (payload.isEmpty) {
      return;
    }

    final handler = _tapHandler;
    if (handler == null) {
      _pendingTapPayload = Map<String, dynamic>.from(payload);
      return;
    }

    await handler(Map<String, dynamic>.from(payload));
  }
}
