import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/screens/payment/payment_screen.dart';
import 'package:dromos/screens/payment/payment_success_screen.dart';
import 'package:dromos/screens/payment/payment_failed_screen.dart';
import 'package:dromos/screens/payment/payment_cancel_screen.dart';
import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:dromos/screens/payment/payment_webview_screen.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/notification_service.dart';
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
  await UserService().init();
  runApp(const MyApp());
}

// request necessary permissions
Future<void> _requestPermissions() async {
  // notification (Android 13+ needs POST_NOTIFICATIONS too)

  // Check if we're on a mobile platform before requesting permissions
  if (!kIsWeb) {
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
    }
    // Add iOS permission handling if needed
    else if (Platform.isIOS) {
      // iOS permission handling
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
    }
  } else {
    // On web, we can't request mobile permissions, but we can show a message
    debugPrint("Running on web - skipping mobile permission requests");
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/home': (context) => const MainScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/payment/history': (context) => const PaymentHistoryScreen(),
        '/payment/webview': (context) => const PaymentWebviewScreen(
              paymentUrl: '',
              orderId: '',
            ),
        '/payment/success': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return PaymentSuccessScreen(orderId: args?['orderId'] ?? '');
        },
        '/payment/failed': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return PaymentFailedScreen(orderId: args?['orderId'] ?? '');
        },
        '/payment/cancel': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return PaymentCancelScreen(orderId: args?['orderId'] ?? '');
        },
      },
    );
  }
}
