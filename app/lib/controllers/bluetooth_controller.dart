import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class MyoDevice {
  final BluetoothDevice bluetoothDevice;
  // final String name;
  String? placement;
  final int id;

  MyoDevice({
    required this.bluetoothDevice,
    // required this.name,
    required this.id,
  });
}

class BluetoothController extends GetxController {
  // Observable list of scan results to update UI automatically
  final scanResults = <ScanResult>[].obs;
  // Observable scanning state
  final isScanning = false.obs;
  final connectedDevices = <MyoDevice>[].obs;
  StreamSubscription? scanSubscription;
  int deviceIdCounter = 0;

  bool get isConnected => connectedDevices.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    FlutterBluePlus.isScanning.listen((isScanning) {
      this.isScanning.value = isScanning;
    });
    Get.log("BluetoothController Initialized");
  }

  Future<void> startScan() async {
    // Request Permissions first
    var statusBleScan = await Permission.bluetoothScan.request();
    var statusBleConnect = await Permission.bluetoothConnect.request();

    if (statusBleScan.isDenied || statusBleConnect.isDenied) {
      Get.snackbar(
        "Permission Denied",
        "Bluetooth permissions are required to scan.",
      );
      return;
    }

    // Check if Bluetooth is supported and on
    try {
      if (await FlutterBluePlus.isSupported == false) {
        Get.snackbar("Error", "Bluetooth not supported");
        return;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return;
    }

    // Cancel existing subscription if any
    scanSubscription?.cancel();

    // Set some options
    FlutterBluePlus.setLogLevel(LogLevel.error);

    // Listen to scan results
    try {
      scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        // Filter out devices without names (unknown devices)
        final filtered = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
        Get.log("Scan results: ${filtered.length} named devices found");
        scanResults.value = filtered;
      });
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }

    // Start scanning
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    // Check if already connected
    for (var myoDevice in connectedDevices) {
      if (myoDevice.bluetoothDevice == device) {
        Get.snackbar("Info", "Device already connected");
        return;
      }
    }

    try {
      await device.connect();

      connectedDevices.add(MyoDevice(bluetoothDevice: device, id: deviceIdCounter));
      deviceIdCounter++;
      // isConnected logic might need to be derived from list length or individual device state
      // For now, if at least one is connected, we can consider 'some' connection active if needed
      // But usually we just care about the list.

      Get.log("Connected to ${device.platformName}");
    } catch (e) {
      Get.snackbar("Error", "Failed to connect: $e");
    }
  }

  Future<void> disconnectDevice(MyoDevice device) async {
    try {
      await device.bluetoothDevice.disconnect();
      for (var myoDevice in connectedDevices) {
        if (myoDevice.id == device.id) {
          connectedDevices.remove(myoDevice);
          break;
        }
      }
      // connectedDevices.remove(device);
      Get.log("Disconnected from ${device.bluetoothDevice.platformName}");
    } catch (e) {
      Get.snackbar("Error", "Failed to disconnect: $e");
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  @override
  void onClose() {
    stopScan();
    scanSubscription?.cancel();
    super.onClose();
  }
}
