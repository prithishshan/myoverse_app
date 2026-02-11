import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/settings_controller.dart';
import 'package:app/widgets/bluetooth_widgets.dart';
import 'package:app/widgets/interactive_svg_viewer.dart';
import 'package:app/theme/app_typography.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bleController = Get.find<BluetoothController>();
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final backgroundColor = settingsController.backgroundColor;
      final isDark = settingsController.isDarkMode;

      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.1),
              radius: 1.1,
              colors: isDark
                  ? [
                      const Color.fromARGB(255, 30, 22, 12),
                      const Color(0xFF0A0A0B),
                    ]
                  : [Colors.white, const Color(0xFFF5F5F5)],
              stops: const [0.0, 1.0],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDevicesSection(bleController, settingsController),
                    const SizedBox(height: AppSpacing.xl),
                    _buildBodySection(bleController, settingsController),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDevicesSection(
    BluetoothController bleController,
    SettingsController settingsController,
  ) {
    return Obx(() {
      final isDark = settingsController.isDarkMode;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Devices', style: AppTypography.label(isDark)),
                if (bleController.isPlacingDevice.value)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTypography.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Select muscle',
                      style: AppTypography.caption(isDark).copyWith(
                        color: AppTypography.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Device cards or empty state
          if (bleController.connectedDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 31),
              child: Center(
                child: Text(
                  'Tap + to add a device',
                  style: AppTypography.bodySecondary(isDark),
                ),
              ),
            )
          else
            SizedBox(
              height: 80, // Slightly larger for better touch targets
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bleController.connectedDevices.length,
                itemBuilder: (context, index) {
                  final device = bleController.connectedDevices[index];
                  final isSelected =
                      bleController.pendingDeviceForAssignment.value?.id ==
                      device.id;
                  return ConnectedDeviceCard(
                    device: device,
                    isSelected: isSelected,
                    onTap: () => {
                      bleController.selectDeviceForReassignment(device),
                      print(device.id),
                      print(bleController.pendingDeviceForAssignment.value?.id),
                    },
                    onDisconnect: () => bleController.disconnectDevice(device),
                  );
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBodySection(
    BluetoothController bleController,
    SettingsController settingsController,
  ) {
    return Obx(() {
      final isDark = settingsController.isDarkMode;

      // Access these observables to ensure Obx rebuilds when they change
      final _ = bleController.connectedDevices.length;
      final __ = bleController.pendingDeviceForAssignment.value;

      // Get muscle IDs that have connected devices (for highlighting)
      final connectedMuscleIds = bleController.getConnectedMuscleIds();
      // print(connectedMuscleIds);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Body', style: AppTypography.label(isDark)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => settingsController.toggleView(),
                  child: Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    color: AppTypography.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Body SVG viewer
          Center(
            child: SizedBox(
              width: 400,
              height: 550,
              child: InteractiveSvgViewer(
                // Key based on highlight list to force rebuild when highlights change
                key: ValueKey('svg_${connectedMuscleIds.join(",")}'),
                assetPath: 'assets/body_model/male/male_front_muscles.svg',
                outlineAssetPath:
                    'assets/body_model/male/male_front_outline.svg',
                outlineColor: isDark ? Colors.white : Colors.black,
                onPartTap: (muscleGroup) {
                  if (!bleController.isPlacingDevice.value) return;

                  final pendingDevice =
                      bleController.pendingDeviceForAssignment.value;
                  if (pendingDevice == null) return;

                  // Check if this muscle is already assigned to ANOTHER device
                  // (Allow reassignment if it's the same device's current muscle)
                  final muscleOwner = bleController.connectedDevices
                      .where((d) => d.muscleGroup?.id == muscleGroup.id)
                      .firstOrNull;

                  if (muscleOwner != null &&
                      muscleOwner.id != pendingDevice.id) {
                    Get.snackbar(
                      'Muscle Already Assigned',
                      'This muscle is connected to another device',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withValues(alpha: 0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(AppSpacing.md),
                      borderRadius: 12,
                    );
                    return;
                  }

                  // Format muscle name
                  final muscleName = muscleGroup.id
                      .split('_')
                      .map(
                        (word) => word.isNotEmpty
                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                            : '',
                      )
                      .join(' ');

                  // Assign muscle to device
                  bleController.assignMuscleToDevice(
                    pendingDevice.id,
                    muscleGroup,
                    muscleName,
                  );

                  Get.snackbar(
                    'Muscle Selected',
                    '$muscleName assigned to ${pendingDevice.deviceName}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppTypography.accentColor.withValues(
                      alpha: 0.9,
                    ),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: 12,
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}
