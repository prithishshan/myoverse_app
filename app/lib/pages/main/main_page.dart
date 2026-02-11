import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:app/pages/analytics/analytics_page.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/settings/settings_page.dart';
import 'package:app/pages/sensor_view/sensor_view_page.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/settings_controller.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final _currentIndex = 1.obs; // Start on home tab (index 1)

  @override
  Widget build(BuildContext context) {
    final bleController = Get.put(BluetoothController());
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isDark = settingsController.isDarkMode;
      final backgroundColor = isDark
          ? const Color(0xFF09090B)
          : const Color(0xFFF5F5F5);

      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: Stack(
          children: [
            // Page content
            Positioned.fill(
              bottom: 100, // Space for floating nav bar
              child: _buildPage(_currentIndex.value),
            ),

            // Floating liquid glass nav bar
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: _buildLiquidGlassNavBar(isDark, settingsController),
            ),

            // Floating Action Button
            Positioned(
              bottom: 110, // Above the floating nav bar
              right: 20,
              child: _buildFAB(bleController, context),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const AnalyticsPage();
      case 1:
        return const HomePage();
      case 2:
        return const SensorViewPage();
      case 3:
        return const SettingsPage();
      default:
        return const HomePage();
    }
  }

  Widget _buildLiquidGlassNavBar(
    bool isDark,
    SettingsController settingsController,
  ) {
    const accentColor = Color(0xFFD17A4A);
    final inactiveColor = isDark ? const Color(0xFF71717A) : Colors.black45;

    // Clean glass effect - minimal and Apple-like
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: glassColor,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: CupertinoIcons.graph_square,
                  activeIcon: CupertinoIcons.graph_square_fill,
                  index: 0,
                  isActive: _currentIndex.value == 0,
                  accentColor: accentColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  icon: CupertinoIcons.house,
                  activeIcon: CupertinoIcons.house_fill,
                  index: 1,
                  isActive: _currentIndex.value == 1,
                  accentColor: accentColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  icon: CupertinoIcons.bolt,
                  activeIcon: CupertinoIcons.bolt_fill,
                  index: 2,
                  isActive: _currentIndex.value == 2,
                  accentColor: accentColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  icon: CupertinoIcons.settings,
                  activeIcon: CupertinoIcons.settings_solid,
                  index: 3,
                  isActive: _currentIndex.value == 3,
                  accentColor: accentColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isActive,
    required Color accentColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: () => _currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? accentColor : inactiveColor,
                size: 26,
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BluetoothController bleController, BuildContext context) {
    const accentColor = Color(0xFFD17A4A);

    return GestureDetector(
      onTap: () {
        // Switch to home tab
        _currentIndex.value = 1;

        // TESTING CODE:
        // bleController.addDummyDevice();

        // PRODUCTION CODE:
        bleController.startScan();
        _showDevicePicker(context, bleController);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.9),
                  accentColor.withValues(alpha: 0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _showDevicePicker(
    BuildContext context,
    BluetoothController bleController,
  ) {
    final settingsController = Get.find<SettingsController>();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Obx(() {
        final isDark = settingsController.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtextColor = isDark ? const Color(0xFF71717A) : Colors.black54;
        const accentColor = Color(0xFFD17A4A);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Devices',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (bleController.isScanning.value)
                          const CupertinoActivityIndicator(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (bleController.scanResults.isEmpty) {
                        return Center(
                          child: Text(
                            bleController.isScanning.value
                                ? 'Scanning...'
                                : 'No devices found',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: bleController.scanResults.length,
                        itemBuilder: (context, index) {
                          final data = bleController.scanResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                bleController.connectToDevice(data.device);
                                Navigator.pop(context);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data
                                                      .device
                                                      .platformName
                                                      .isNotEmpty
                                                  ? data.device.platformName
                                                  : "Unknown Device",
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data.device.remoteId.toString(),
                                              style: TextStyle(
                                                color: subtextColor,
                                                fontSize: 12,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "${data.rssi} dBm",
                                          style: const TextStyle(
                                            color: accentColor,
                                            fontSize: 14,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ).then((_) {
      bleController.stopScan();
    });
  }
}
