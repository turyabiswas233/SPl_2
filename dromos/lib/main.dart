import 'dart:io';

import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/noti.dart';
import 'package:dromos/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  Color accentColor = ConstColor.primaryPurple;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: accentColor.withAlpha(50),
      systemNavigationBarColor: accentColor.withAlpha(200),
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  NotiService().initNoti();
  runApp(MyApp());
}

// request necessary permissions
Future<void> _requestPermissions() async {
  // notification (Android 13+ needs POST_NOTIFICATIONS too)

  if (Platform.isAndroid) {
    final statuses = await [
      Permission.location,
      Permission.notification,
      Permission.camera,
    ].request();

    if (statuses[Permission.location]!.isGranted) {
      debugPrint("Location permission granted");
    } else {
      debugPrint("Location permission denied");
    }
    if (statuses[Permission.notification]!.isGranted) {
      debugPrint("Notification permission granted");
    } else {
      debugPrint("Notification permission denied");
    }
    if (statuses[Permission.camera]!.isGranted) {
      debugPrint("Camera permission granted");
    } else {
      debugPrint("Camera permission denied");
    }
  } else {
    // may be something erro
    debugPrint("something error in access");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dromos - Enjoy the ride',
      theme: appTheme(),
      home: const HomeScreen(),
    );
  }
}
