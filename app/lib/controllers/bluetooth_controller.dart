import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  // Observable list of scan results to update UI automatically
  final scanResults = <ScanResult>[].obs;
  // Observable scanning state
  final isScanning = false.obs;
  final isConnected = false.obs;
  final connectedDevice = Rxn<BluetoothDevice>();

  StreamSubscription? scanSubscription;
  
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
      Get.snackbar("Permission Denied", "Bluetooth permissions are required to scan.");
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
            final filtered = results.where((r) => r.device.platformName.isNotEmpty).toList();
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
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      // await Future.delayed(const Duration(milliseconds: 100), () => connectedDevice.value!.disconnect());
    }
    try {
      await device.connect();
      connectedDevice.value = device;
      isConnected.value = true;
      await device.discoverServices();
      Get.log("Connected to ${device.platformName}");
    } catch (e) {
      Get.snackbar("Error", e.toString());
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
