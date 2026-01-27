import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  final Widget child;

  const CameraOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Semi-transparent overlay with cutout for ID card
        ColoredBox(
          color: Colors.black54,
          child: Stack(
            children: [
              // Create the frame cutout
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Instructions
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Align your ID card within the frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Make sure all text is clearly visible',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
