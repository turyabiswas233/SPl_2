import 'dart:io';
import 'dart:async';
import 'package:dromos/pages/home/default_page.dart';
import 'package:dromos/pages/no_internet_page.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/notification_service.dart';
import 'package:dromos/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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

  try {
    // Load environment variables globally
    await dotenv.load(fileName: ".env.local");
    String? token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token != null && token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
    }
  } catch (e) {
    debugPrint("Environment load error: $e");
  }

  /// request necessary permissions before app starts
  await _requestPermissions();

  // Load saved session & fetch profile if token exists
  await UserService().init();
  Widget defaultHome = const DefaultHomeScreen();
  if (UserService().isLoggedIn) {
    await UserService().fetchProfile();
    defaultHome = const MainScreen();
  }

  await NotificationController.initNotification();
  runApp(MyApp(defaultHome: defaultHome));
}

// ... rest of main.dart (kept as is)
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
    debugPrint("something error in access");
  }
}

class MyApp extends StatefulWidget {
  final Widget defaultHome;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key, required this.defaultHome});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _startSplashTimer();
    initConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_isInternetAvailable);
    super.initState();
  }

  bool _isInternetConnected = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> initConnection() async {
    List<ConnectivityResult> results;
    try {
      results = await Connectivity().checkConnectivity();
    } catch (e) {
      results = [ConnectivityResult.none];
    }
    return _isInternetAvailable(results);
  }

  Future<void> _isInternetAvailable(List<ConnectivityResult> results) async {
    setState(() {
      _isInternetConnected = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  bool _timeoutSplash = false;
  Future<void> _startSplashTimer() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() { _timeoutSplash = true; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dromos - Enjoy the ride',
      theme: appTheme(),
      home: !_timeoutSplash ? const SplashScreen() : (!_isInternetConnected ? NoInternetConnectionScreen(onRetry: initConnection) : widget.defaultHome),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/logo.png'), width: 150),
            CircularProgressIndicator(color: ConstColor.primaryPurple, trackGap: 3),
          ],
        ),
      ),
    );
  }
}
