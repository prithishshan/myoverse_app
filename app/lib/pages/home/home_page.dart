import 'package:app/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:app/widgets/some_muscles.dart';
import 'package:flutter/material.dart'
    show Colors; // Only using Colors if needed
import 'package:get/get.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/placement_controller.dart';
import 'package:app/widgets/bluetooth_widgets.dart';
import 'package:app/widgets/interactive_svg_viewer.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Devices',
            style: TextStyle(
              color: Color(0xFFA1A1AA), // zinc-400
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: Obx(() {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bleController.connectedDevices.length + 1,
              itemBuilder: (context, index) {
                if (index < bleController.connectedDevices.length) {
                  final device = bleController.connectedDevices[index];
                  return ConnectedDeviceCard(
                    device: device,
                    onDisconnect: () => bleController.disconnectDevice(device),
                  );
                } else {
                  return AddDeviceCard(
                    onTap: () {
                      bleController.startScan();
                      _showDevicePicker(context);
                    },
                  );
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBodyModesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Body Modes',
                style: TextStyle(
                  color: Color(0xFFA1A1AA), // zinc-400
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => placementController.toggleView(),
                child: const Icon(
                  CupertinoIcons.arrow_2_circlepath,
                  color: accentColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          child: Column(
            children: [
              // Row with buttons removed

              // Scale 0.3 maps the approx 3.3x coordinate range to the viewport.
              Container(
                width: 450,
                height: 600,
                color: Colors.transparent, // helper background to see bounds
                child: InteractiveSvgViewer(
                  assetPath: 'assets/body_model/male/male_front_muscles.svg',
                  outlineAssetPath:
                      'assets/body_model/male/male_front_outline.svg',
                  onPartTap: (id) {
                    print('Tapped muscle part: $id');

                    // Create a temporary placement for the selected muscle
                    final placement = Placement(
                      id: id,
                      title: id
                          .split('_')
                          .map(
                            (word) => word[0].toUpperCase() + word.substring(1),
                          )
                          .join(' '),
                      imageUrl:
                          "assets/body_model/male/male_front_muscles.svg", // Fallback/Default
                      directions: "Sensor placement for $id",
                    );

                    placementController.placementSelected.value = placement;

                    // Navigate immediately to sensor readout
                    Get.toNamed(AppRoutes.sensorReadout);
                  },
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(height: 12),
        // ...bodyModes.map((mode) => _buildBodyModeCard(mode)),
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
