import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dromos/utils/colors.dart';

class NotificationService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // initialize notification settings
  Future<void> initNotification() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notificationPlugin.initialize(initSettings);

    debugPrint("\x1B[35mNOTIFICATION_DEBUG: Notification service initialized\x1B[0m");
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
    required String id,
    String? title,
    String? body,
  }) async {
    debugPrint(title);
    if (!isInitialized) {
      debugPrint(
        "\x1B[31mNOTIFICATION_DEBUG: Notification service not initialized\x1B[0m",
      );
      await initNotification().then((_) {
        showNotification(id: id, title: title, body: body);
      });
      return;
    }
    notificationPlugin.show(id.hashCode, title, body, _notificationDetails());
  }
}
