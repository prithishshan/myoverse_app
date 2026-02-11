import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:app/controllers/settings_controller.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/widgets/liquid_glass_card.dart';
import 'package:app/theme/app_typography.dart';

class ConnectedDeviceCard extends StatelessWidget {
  final MyoDevice device;
  final VoidCallback onDisconnect;
  final VoidCallback? onTap;
  final bool isSelected;

  const ConnectedDeviceCard({
    super.key,
    required this.device,
    required this.onDisconnect,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isDark = settingsController.isDarkMode;
      final textColor = isDark ? Colors.white : Colors.black87;

      // Determine display text - always show something
      final displayText =
          device.muscleName ?? (isSelected ? 'Tap muscle' : 'No muscle');
      final textOpacity = device.muscleName != null
          ? 1.0
          : (isSelected ? 0.6 : 0.4);

      return GestureDetector(
        onTap: onTap,
        child: LiquidGlassCard(
          width: 90,
          height: 80,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          borderRadius: 14,
          borderColor: isSelected ? AppTypography.accentColor : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device Name
              Text(
                device.deviceName,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Muscle Name container
              SizedBox(
                height: 36,
                child: Center(
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: textOpacity),
                      fontSize: 13,
                      fontWeight: device.muscleName != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDisconnect,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.25),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
