import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:app/controllers/settings_controller.dart';
import 'package:app/widgets/liquid_glass_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isDark = settingsController.isDarkMode;
      final backgroundColor = settingsController.backgroundColor;
      final textColor = settingsController.textColor;
      final subtextColor = settingsController.subtextColor;
      const accentColor = Color(0xFFD17A4A);

      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Appearance Section
                      Text(
                        'Appearance',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Theme Toggle Card
                      LiquidGlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDark
                                      ? CupertinoIcons.moon_fill
                                      : CupertinoIcons.sun_max_fill,
                                  color: accentColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dark Mode',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDark ? 'On' : 'Off',
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 13,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: isDark,
                              activeTrackColor: accentColor,
                              onChanged: (value) {
                                settingsController.setTheme(value);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // About Section
                      Text(
                        'About',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      LiquidGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Version',
                              '1.0.0',
                              textColor,
                              subtextColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                height: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            _buildInfoRow(
                              'Developer',
                              'Myoverse Team',
                              textColor,
                              subtextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: subtextColor,
            fontSize: 15,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
