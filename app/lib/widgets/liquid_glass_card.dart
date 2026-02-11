import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:app/controllers/settings_controller.dart';

/// A reusable card widget with subtle liquid glass styling.
/// Clean Apple-inspired design with minimal visual noise.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final VoidCallback? onTap;
  final Color? borderColor;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 14.0,
    this.blurAmount = 20.0,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isDark =
          settingsController.currentTheme.value.brightness == Brightness.dark;

      // Subtle glass effect - clean and minimal
      final glassColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.8);
      final defaultBorderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);

      final effectiveBorderColor = borderColor ?? defaultBorderColor;
      const effectiveBorderWidth = 1.0; // Fixed width to prevent layout shift

      Widget cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: glassColor,
              border: Border.all(
                color: effectiveBorderColor,
                width: effectiveBorderWidth,
              ),
            ),
            child: child,
          ),
        ),
      );

      if (margin != null) {
        cardContent = Padding(padding: margin!, child: cardContent);
      }

      if (onTap != null) {
        return GestureDetector(onTap: onTap, child: cardContent);
      }

      return cardContent;
    });
  }
}
