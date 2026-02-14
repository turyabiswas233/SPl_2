import 'dart:io';
import 'dart:async';
import 'package:dromos/pages/home/default_page.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/notification_service.dart';
import 'package:dromos/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: ConstColor.primaryColor.withAlpha(50),
      systemNavigationBarColor: ConstColor.primaryPurple.withAlpha(200),
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();

  /// request necessary permissions before app starts
  await _requestPermissions();

  /// initialize notification service
  await NotificationService().initNotification();

  // Load saved session & fetch profile if token exists
  await UserService().init();
  Widget defaultHome = const DefaultHomeScreen();
  if (UserService().isLoggedIn) {
    await UserService().fetchProfile();
    defaultHome = const MainScreen();
  }
  runApp(MyApp(defaultHome: defaultHome));
}

// request necessary permissions
Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    List<Permission> permissionList = [
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.mediaLibrary,
      Permission.photos,
    ];
    final statuses = await [...permissionList].request();

    statuses.forEach((key, val) {
      if (val.isDenied) {
        debugPrint("${val.toString()} permission denied");
      } else if (val.isGranted) {
        debugPrint("${val.toString()} permission granted");
      }
    });
  } else {
    // may be something error
    debugPrint("something error in access");
  }
}

class MyApp extends StatelessWidget {
  final Widget defaultHome;

  const MyApp({super.key, required this.defaultHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dromos - Enjoy the ride',
      theme: appTheme(),
      home: SplashScreen(defaultHome: defaultHome),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Widget defaultHome;
  const SplashScreen({super.key, required this.defaultHome});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.defaultHome),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(image: AssetImage('assets/logo.png'), width: 150),
      ),
    );
  }
}
