import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dromos/utils/colors.dart';

class AppVersion extends StatelessWidget {
  const AppVersion({super.key});

  Future<PackageInfo> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _getAppVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        } else {
          return Text(
            "Version ${snapshot.data?.version}+${snapshot.data?.buildNumber}",
            textAlign: TextAlign.center,
            style: TextStyle(color: ConstColor.primaryPurple),
          );
        }
      },
    );
  }
}
