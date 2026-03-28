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

  /// load environment variables
  await dotenv.load(fileName: '.env.local');

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
  // Configure Mapbox access token from environment variable
  String accessToken = dotenv.get("MAPBOX_ACCESS_TOKEN");
  if (accessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(accessToken);
  } else {
    debugPrint(
      "Warning: MAPBOX_ACCESS_TOKEN is not set in .env.local. Map features may not work properly.",
    );
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

class MyApp extends StatefulWidget {
  final Widget defaultHome;

  const MyApp({super.key, required this.defaultHome});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _startSplashTimer();
    initConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _isInternetAvailable,
    );
    super.initState();
  }

  bool _isInternetConnected = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> initConnection() async {
    List<ConnectivityResult> results;

    try {
      debugPrint("Retrying connection...");
      results = await Connectivity().checkConnectivity();
    } catch (e) {
      debugPrint("Couldn't Check Connectivity Status: $e");

      results = [ConnectivityResult.none];
    }
    return _isInternetAvailable(results);
  }

  Future<void> _isInternetAvailable(List<ConnectivityResult> results) async {
    setState(() {
      _isInternetConnected =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);
    });
  }

  void _retryConnection() {
    initConnection();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  bool _timeoutSplash = false;

  Future<void> _startSplashTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _timeoutSplash = true;
    });
  }

  Widget _getInitialScreen() {
    if (!_timeoutSplash) {
      return const SplashScreen();
    }

    if (!_isInternetConnected) {
      return NoInternetConnectionScreen(onRetry: _retryConnection);
    }

    return widget.defaultHome;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dromos - Enjoy the ride',
      theme: appTheme(),
      home: _getInitialScreen(),
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
          mainAxisAlignment: .center,
          children: [
            Image(image: AssetImage('assets/logo.png'), width: 150),
            CircularProgressIndicator(
              color: ConstColor.primaryPurple,
              trackGap: 3,
            ),
          ],
        ),
      ),
    );
  }
}
