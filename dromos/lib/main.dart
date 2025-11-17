import 'dart:io';

import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/utils/_colors.dart';
import 'package:dromos/utils/noti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
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
    // may be something error
    debugPrint("something error in access");
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  ConstColor cc = ConstColor();
  late Map<int, Color> light = cc.light();
  late Map<int, Color> dark = cc.dark();

  @override
  Widget build(BuildContext context) {
    late final Color? primaryColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
        ? light[1]
        : dark[1];
    late final Color? bgCol =
        MediaQuery.of(context).platformBrightness == Brightness.light
        ? light[2]
        : dark[2];
    late final Color secondaryColor = ConstColor.primaryPurple;
    late SystemUiOverlayStyle sos =
        MediaQuery.of(context).platformBrightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: sos,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dromos - Enjoy the ride',
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useSystemColors: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontFamilyFallback: GoogleFonts.poppins().fontFamilyFallback,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: secondaryColor,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
