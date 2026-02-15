import 'package:dromos/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NoInternetConnectionScreen extends StatelessWidget {
  final void Function()? onRetry;
  static bool _isLoadingNetworkStatus = false;

  const NoInternetConnectionScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/no_internet.json',
              width: MediaQuery.of(context).size.width,
              height: 200,
              frameRate: FrameRate(120),
            ),
            SizedBox(height: 24),
            Text(
              "No Internet Connection",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Please check your internet connection and try again!",
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: ConstColor.primaryColor.withAlpha(80),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoadingNetworkStatus
                  ? null
                  : () {
                      _isLoadingNetworkStatus = true;
                      onRetry!();
                      _isLoadingNetworkStatus = false;
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: ConstColor.primaryBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 12,
                ), // Adjust padding
                minimumSize: Size.zero, // Remove default min size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isLoadingNetworkStatus ? "Checking..." : "Retry",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ConstColor.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
