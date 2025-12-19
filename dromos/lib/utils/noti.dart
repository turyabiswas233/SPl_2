import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dromos/utils/colors.dart';
class NotiService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // initialize notification settings
  Future<void> initNoti() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notificationPlugin.initialize(initSettings);
    debugPrint("NOTI_DEBUG: Notification service initialized");
    _isInitialized = true;
  }

  // notification details setup
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Page Changes',
      channelDescription: 'channel_description',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: ConstColor.primaryPurple,
      colorized: true,
    );

    return const NotificationDetails(android: androidDetails);
  }

  // show notification
  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
  }) async {
    debugPrint(title);
    if (!isInitialized) {
      debugPrint("Notification service not initialized");
    }
    return notificationPlugin.show(id, title, body, _notificationDetails());
  }
}
