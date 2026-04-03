import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dromos/utils/colors.dart';

class NotificationController {
  static final notificationPlugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  // initialize notification settings
  static Future<void> initNotification() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notificationPlugin.initialize(settings: initSettings);
    debugPrint("NOTIFICATION_DEBUG: Notification service initialized");
    _isInitialized = true;
  }

  // notification details setup
  static NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Page Changes',
      channelDescription: 'channel_description',
      importance: Importance.high,
      priority: Priority.high,
      color: ConstColor.primaryPurple,
      colorized: false,
      channelShowBadge: true,
      icon: '@mipmap/ic_launcher'
    );

    return const NotificationDetails(android: androidDetails);
  }

  ///
  /// Create a new notification
  /// id: notification id
  /// title: notification title
  /// body: notification body
  /// payload: notification payload | notification ID
  static Future<void> createNewNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!isInitialized) {
      debugPrint("Notification service not initialized");
      return;
    }
    notificationPlugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: _notificationDetails(),
    );
  }
}
