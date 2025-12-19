import 'dart:io';

import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/noti.dart';
import 'package:dromos/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {

  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: accentColor.withAlpha(50),
        systemNavigationBarColor: accentColor.withAlpha(200)
      )
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
    ].request();

    if (statuses[Permission.locationWhenInUse]?.isGranted == true) {
      debugPrint('Location Only When in Use is granted');
    } else {
      debugPrint('No permission for location is granted');
    }

    if (statuses[Permission.notification]?.isGranted == true) {
      debugPrint('Notification permission is granted');
    } else {
      debugPrint('No permission for notification is granted');
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
