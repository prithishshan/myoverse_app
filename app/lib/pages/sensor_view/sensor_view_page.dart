import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/settings_controller.dart';
import 'package:app/widgets/muscle_widget.dart';
import 'package:app/widgets/bilateral_muscle_widget.dart';

class SensorViewPage extends StatefulWidget {
  const SensorViewPage({super.key});

  @override
  State<SensorViewPage> createState() => _SensorViewPageState();
}

class _SensorViewPageState extends State<SensorViewPage> {
  final PageController _pageController = PageController();
  final _currentPage = 0.obs;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _currentPage.value = _pageController.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleController = Get.find<BluetoothController>();
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final isDark = settingsController.isDarkMode;
      final backgroundColor = settingsController.backgroundColor;
      final pages = _buildSensorPages(bleController);

      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: backgroundColor,
          middle: Text(
            'Sensor View',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          border: null,
        ),
        child: SafeArea(
          child: pages.isEmpty
              ? _buildEmptyState(isDark)
              : Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        children: pages,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPageIndicator(
                      pages.length,
                      _currentPage.value,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      );
    });
  }

  List<Widget> _buildSensorPages(BluetoothController bleController) {
    final pages = <Widget>[];
    final connectedDevices = bleController.connectedDevices;
    final processedBilateralPairs = <String>{};

    // First, add individual pages for ALL connected devices
    for (var device in connectedDevices) {
      if (device.muscleGroup?.id == null) continue;
      pages.add(_buildIndividualPage(device));
    }

    // Then, add bilateral pages for paired devices
    for (var device in connectedDevices) {
      if (device.muscleGroup?.id == null) continue;

      final muscleId = device.muscleGroup!.id;
      final pairedDevice = _findPairedDevice(device, connectedDevices);

      if (pairedDevice != null) {
        // Create a unique key for this pair to avoid duplicates
        final pairKey = [muscleId, pairedDevice.muscleGroup!.id]..sort();
        final pairId = pairKey.join('_');

        if (!processedBilateralPairs.contains(pairId)) {
          pages.add(_buildBilateralPage(device, pairedDevice));
          processedBilateralPairs.add(pairId);
        }
      }
    }

    return pages;
  }

  MyoDevice? _findPairedDevice(MyoDevice device, List<MyoDevice> devices) {
    if (device.muscleGroup?.id == null) return null;

    final muscleId = device.muscleGroup!.id;
    String? pairId;

    // Handle suffix pattern: biceps_left -> biceps_right
    if (muscleId.endsWith('_left')) {
      pairId = muscleId.replaceAll('_left', '_right');
    } else if (muscleId.endsWith('_right')) {
      pairId = muscleId.replaceAll('_right', '_left');
    } else if (muscleId.endsWith('_l')) {
      pairId = muscleId.replaceAll(RegExp(r'_l$'), '_r');
    } else if (muscleId.endsWith('_r')) {
      pairId = muscleId.replaceAll(RegExp(r'_r$'), '_l');
    }
    // Handle prefix pattern: left_bicep -> right_bicep
    else if (muscleId.startsWith('left_')) {
      pairId = muscleId.replaceFirst('left_', 'right_');
    } else if (muscleId.startsWith('right_')) {
      pairId = muscleId.replaceFirst('right_', 'left_');
    } else if (muscleId.startsWith('l_')) {
      pairId = muscleId.replaceFirst('l_', 'r_');
    } else if (muscleId.startsWith('r_')) {
      pairId = muscleId.replaceFirst('r_', 'l_');
    }

    if (pairId != null) {
      return devices.firstWhereOrNull((d) => d.muscleGroup?.id == pairId);
    }

    return null;
  }

  Widget _buildIndividualPage(MyoDevice device) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            device.muscleName ?? 'Unknown Muscle',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            device.deviceName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 1,
              child: MuscleWidget(
                streams: _getMuscleStreams(device.emgConn, 6),
                avgStreams: _getMuscleStreams(device.emgConn, 3),
                muscleGroup: device.muscleGroup!,
                showRings: true,
              ),
            ),
          ),
          if (device.imuConn != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ImuDataCard(stream: device.imuConn!),
            ),
        ],
      ),
    );
  }

  Widget _buildBilateralPage(MyoDevice leftDevice, MyoDevice rightDevice) {
    final isLeftFirst = leftDevice.muscleGroup?.id.contains('left') ?? false;
    final left = isLeftFirst ? leftDevice : rightDevice;
    final right = isLeftFirst ? rightDevice : leftDevice;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${left.muscleName ?? 'Unknown'} (Bilateral)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${left.deviceName} & ${right.deviceName}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 400,
            child: BilateralMuscleWidget(
              streams: [
                ..._getMuscleStreams(left.emgConn, 6),
                ..._getMuscleStreams(right.emgConn, 6),
              ],
              avgStreams: [
                ..._getMuscleStreams(left.emgConn, 1),
                ..._getMuscleStreams(right.emgConn, 1),
              ],
              leftMuscleGroup: left.muscleGroup!,
              rightMuscleGroup: right.muscleGroup!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.eye_slash,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No Sensors Connected',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect devices from the Home tab',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount, int currentPage, bool isDark) {
    if (pageCount <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFD17A4A)
                : isDark
                ? Colors.white24
                : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // Placeholder for EMG streams - currently returns 0.0 ("silence") until EMG format is defined
  List<Stream<double>> _getMuscleStreams(
    Stream<List<int>>? emgStream,
    int count,
  ) {
    // In the future, we will transform emgStream into distinct 0.0-1.0 intensity streams
    // For now, return constant 0 streams
    return List.generate(count, (_) => Stream.value(0.0).asBroadcastStream());
  }
}

class ImuDataCard extends StatelessWidget {
  final Stream<List<int>> stream;

  const ImuDataCard({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.length < 14) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        // Parse Little Endian
        // Seq (0-1) - uint16
        final seq = data[0] | (data[1] << 8);

        // Helper for Int16 Little Endian
        int getInt16(int idx) {
          int val = data[idx] | (data[idx + 1] << 8);
          if (val > 32767) val -= 65536;
          return val;
        }

        final ax = getInt16(2) / 100.0;
        final ay = getInt16(4) / 100.0;
        final az = getInt16(6) / 100.0;

        final gx = getInt16(8) / 10.0;
        final gy = getInt16(10) / 10.0;
        final gz = getInt16(12) / 10.0;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMU Data (Seq: $seq)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _buildRow(
                'Accel',
                '${ax.toStringAsFixed(2)}, ${ay.toStringAsFixed(2)}, ${az.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _buildRow(
                'Gyro',
                '${gx.toStringAsFixed(1)}, ${gy.toStringAsFixed(1)}, ${gz.toStringAsFixed(1)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
