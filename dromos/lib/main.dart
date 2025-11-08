import 'dart:io';

import 'package:dromos/app_shell.dart';
import 'package:dromos/utils/_colors.dart';
import 'package:dromos/utils/noti.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  NotiService().initNoti();
  runApp(const MyApp());
}

// requset necessary permissions
Future<void> _requestPermissions() async {
  // notification (Android 13+ needs POST_NOTIFICATIONS too)
  await Permission.notification.request();

  if (Platform.isAndroid) {
    // request storage-related permissions together; on Android 13+ the READ_MEDIA_* permissions are used
    final statuses = await [
      Permission.location,
      Permission.photos,
      Permission
          .manageExternalStorage, // will require user to grant in system settings on newer Android
    ].request();

    if (statuses[Permission.manageExternalStorage]?.isGranted == true) {
      debugPrint('Manage external storage granted');
    } else if (statuses[Permission.storage]?.isGranted == true) {
      debugPrint('Legacy storage permission granted');
    } else {
      debugPrint(
        'Storage permission not granted; you may need to open settings',
      );
      // optionally open settings:
      // await openAppSettings();
    }
  } else {
    // iOS: request Photos if needed
    final status = await Permission.photos.request();
    debugPrint('iOS photos permission: $status');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dromos - Enjoy the ride',
      theme: ThemeData(
        primaryColor: ConstColor.primary_purple,
        fontFamily: "Poppins",
        fontFamilyFallback: ["Poppins"],
      ),
      home: const AppShell(),
    );
  }
}
