import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class WaitingOverlay extends StatelessWidget {
  final String? captionText;
  const WaitingOverlay({super.key, this.captionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ConstColor.primaryBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: ConstColor.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please wait...',
              style: ConstFonts.semibold(
                size: 24,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (captionText != null)
              Text(
                captionText!,
                style: ConstFonts.semibold(
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
