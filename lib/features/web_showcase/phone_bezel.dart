import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Wraps the interactive app inside a realistic phone mockup / bezel for desktop.
class PhoneBezel extends StatelessWidget {
  final Widget child;

  const PhoneBezel({super.key, required this.child});

  static const double targetWidth = 390.0;
  static const double targetHeight = 824.0;
  static const double phoneAspectRatio = targetWidth / targetHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute available space, preserving phone proportions.
        final maxH = math.min(targetHeight, constraints.maxHeight - 40.0);
        final height = math.max(500.0, maxH);
        final width = height * phoneAspectRatio;
        final scale = height / targetHeight;

        const outerBorderRadius = 48.0;
        const innerBorderRadius = 36.0;

        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outerBorderRadius * scale),
              color: const Color(0xFF1C1C1F),
              border: Border.all(
                color: const Color(0xFF2C2C30),
                width: 4 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFFFF5A54).withValues(alpha: 0.12),
                  blurRadius: 70,
                  spreadRadius: -10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(10 * scale),
            child: Stack(
              children: [
                // Screen content with simulated mobile safe area & screen size.
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(innerBorderRadius * scale),
                    child: Container(
                      color: const Color(0xFF101010),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: Size(width, height),
                          padding: EdgeInsets.only(
                            top: 40 * scale,
                            bottom: 24 * scale,
                          ),
                          viewPadding: EdgeInsets.only(
                            top: 40 * scale,
                            bottom: 24 * scale,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),

                // Top camera notch / dynamic island pill.
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8 * scale),
                    child: IgnorePointer(
                      child: Container(
                        width: 105 * scale,
                        height: 24 * scale,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 9 * scale,
                              height: 9 * scale,
                              margin: EdgeInsets.only(right: 10 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF232328),
                                  width: 1 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom home indicator bar.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6 * scale),
                    child: IgnorePointer(
                      child: Container(
                        width: 110 * scale,
                        height: 4 * scale,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
