import 'package:app/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors; // Only using Colors if needed
import 'package:get/get.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/placement_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BluetoothController bleController = Get.find<BluetoothController>();
  final PlacementController placementController =
      Get.find<PlacementController>();

  // Colors from the design
  static const Color accentColor = Color(0xFFD17A4A);
  static const Color backgroundColor = Colors.black; // bg-black
  static const Color surfaceColor = Color(0xFF18181B); // bg-zinc-900 (approx)
  static const Color borderColor = Color(
    0xFF27272A,
  ); // border-zinc-900 (approx)
  static const Color textColor = Colors.white;
  static const Color subtextColor = Color(0xFF71717A); // text-zinc-500

  // Images from App.tsx
  final List<Placement> bodyModes = placements;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: CustomScrollView(
        slivers: [
          // Header
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        CupertinoIcons.bolt_horizontal_circle_fill,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'MyoVerse',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Activity Monitor',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildBluetoothCard(),
                const SizedBox(height: 24),
                _buildBodyModesSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Obx(() {
                      return Icon(
                        bleController.isScanning.value
                            ? CupertinoIcons.bluetooth
                            : CupertinoIcons.bluetooth, // Use appropriate icons
                        color: bleController.isScanning.value
                            ? accentColor
                            : subtextColor,
                        size: 24,
                      );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Connection',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Obx(
                            () => Text(
                              bleController.isScanning.value
                                  ? 'Scanning...'
                                  : 'Not connected',
                              style: const TextStyle(
                                color: subtextColor,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: bleController.isScanning.value
                        ? accentColor
                        : const Color(0xFF3F3F46), // zinc-700
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            bool isScanning = bleController.isScanning.value;
            // Use CupertinoButton.filled for primary action loop
            return SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: isScanning ? const Color(0xFF27272A) : accentColor,
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  if (isScanning) {
                    bleController.stopScan();
                  } else {
                    bleController.startScan();
                    _showDevicePicker(context);
                  }
                },
                child: Text(
                  isScanning ? 'Stop Scanning' : 'Connect Device',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isScanning ? subtextColor : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBodyModesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Body Modes',
            style: TextStyle(
              color: Color(0xFFA1A1AA), // zinc-400
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...bodyModes.map((mode) => _buildBodyModeCard(mode)),
      ],
    );
  }

  Widget _buildBodyModeCard(Placement mode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        height: 80, // h-20
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12.0), // rounded-xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            placementController.placementSelected.value = mode;
            Get.toNamed(AppRoutes.patchPlacement);
          },
          child: Row(
            children: [
              // Image section
              SizedBox(
                width: 96, // w-24
                height: double.infinity,
                child: Image.asset(
                  mode.imageUrl,
                  fit: BoxFit.cover,
                  color: const Color.fromRGBO(255, 255, 255, 0.6), // opacity-60
                  colorBlendMode: BlendMode.modulate,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF18181B)),
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mode.title,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        color: Color(0xFF52525B), // zinc-600
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDevicePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 500,
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Available Devices',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (bleController.scanResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'No devices found',
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
                          // Connect logic
                          bleController.connectToDevice(data.device);
                          Navigator.pop(context); // Close modal on selection
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            // border: Border.all(color: cardBorderColor), // Removing border for cleaner look
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.device.platformName.isNotEmpty
                                        ? data.device.platformName
                                        : "Unknown Device",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.device.remoteId.toString(),
                                    style: const TextStyle(
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
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Trigger when modal is dismissed (by barrier or pop)
      bleController.stopScan();
    });
  }
}
