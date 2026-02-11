import 'dart:async';
import 'package:app/models/muscle_part.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class MyoDevice {
  final BluetoothDevice? bluetoothDevice; // Made nullable for dummy devices
  // final DummyDevice? dummyDevice; // For testing
  MuscleGroup? muscleGroup;
  String? muscleName;
  final int id;
  Stream<List<int>>? imuConn; // Stream for incoming data from the device
  Stream<List<int>>? emgConn; // Stream for incoming data from the device

  MyoDevice({
    this.bluetoothDevice,
    required this.id,
    this.muscleGroup,
    this.muscleName,
  });

  String get deviceName {
    if (bluetoothDevice != null) return bluetoothDevice!.platformName;
    return "Unknown";
  }
}

class BluetoothController extends GetxController {
  // Observable list of scan results to update UI automatically
  final scanResults = <ScanResult>[].obs;
  // Observable scanning state
  final isScanning = false.obs;
  final connectedDevices = <MyoDevice>[].obs;
  StreamSubscription? scanSubscription;
  int deviceIdCounter = 0;

  // Device awaiting muscle assignment (for new connection flow)
  final pendingDeviceForAssignment = Rxn<MyoDevice>();

  // Flag to indicate we're in device placement mode
  final isPlacingDevice = false.obs;

  bool get isConnected => connectedDevices.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // Comment out for testing without Bluetooth
    FlutterBluePlus.isScanning.listen((isScanning) {
      this.isScanning.value = isScanning;
    });
    Get.log("BluetoothController Initialized");
  }

  // / Add a dummy device for testing
  // void addDummyDevice({String name = "Myo Sensor 1"}) {
  //   // final dummyDev = DummyDevice(name: name, id: "DUMMY_${deviceIdCounter}");

  //   final newDevice = MyoDevice(bluetoothDevice: null, id: deviceIdCounter);
  //   deviceIdCounter++;
  //   connectedDevices.add(newDevice);

  //   // Set this device as pending for muscle assignment
  //   pendingDeviceForAssignment.value = newDevice;
  //   isPlacingDevice.value = true;

  //   Get.log("Added dummy device: $name");
  // }

  /// Select an existing device for muscle reassignment
  void selectDeviceForReassignment(MyoDevice device) {
    pendingDeviceForAssignment.value = device;
    isPlacingDevice.value = true;
    connectedDevices.refresh();
    Get.log("Selected device ${device.deviceName} for reassignment");
  }

  Future<void> startScan() async {
    // FOR TESTING: Skip actual BLE scan, just simulate
    isScanning.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isScanning.value = false;
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

      final newDevice = MyoDevice(bluetoothDevice: device, id: deviceIdCounter);

      // Set this device as pending for muscle assignment
      pendingDeviceForAssignment.value = newDevice;
      isPlacingDevice.value = true;
      await Future.delayed(const Duration(milliseconds: 300));
      await device.discoverServices();
      print("services: ${device.servicesList}");
      device.servicesList?.forEach((service) {
        print("service: ${service.uuid}");
        service.characteristics.forEach((characteristic) {
          print("characteristic: ${characteristic.uuid}");
          if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef2") {
            characteristic.setNotifyValue(true);
            newDevice.imuConn = characteristic.onValueReceived;
            // characteristic.onValueReceived.listen((value) {
            //   print("value: $value");
            // });
          }
        });
      });
      deviceIdCounter++;
      connectedDevices.add(newDevice);
      Get.log("Connected to ${device.platformName}");
    } catch (e) {
      Get.snackbar("Error", "Failed to connect: $e");
    }
  }

  /// Assign a muscle to a device
  void assignMuscleToDevice(
    int deviceId,
    MuscleGroup muscleGroup,
    String muscleName,
  ) {
    for (var device in connectedDevices) {
      if (device.id == deviceId) {
        device.muscleGroup?.highlighted = false;
        device.muscleGroup = muscleGroup;
        device.muscleName = muscleName;
        break;
      }
    }

    // Clear pending assignment
    pendingDeviceForAssignment.value = null;
    isPlacingDevice.value = false;

    // Force refresh the connected devices list
    connectedDevices.refresh();

    Get.log("Assigned muscle $muscleName to device $deviceId");
  }

  /// Cancel the pending device assignment
  void cancelDeviceAssignment() {
    pendingDeviceForAssignment.value = null;
    isPlacingDevice.value = false;
  }

  /// Get the list of muscle IDs that have connected devices
  List<String> getConnectedMuscleIds() {
    return connectedDevices
        .where((d) => d.muscleGroup != null)
        .map((d) => d.muscleGroup!.id)
        .toList();
  }

  Future<void> disconnectDevice(MyoDevice device) async {
    try {
      await device.bluetoothDevice?.disconnect();
      device.muscleGroup?.highlighted = false;
    } catch (e) {
      Get.snackbar("Error", "Failed to disconnect: $e");
    }

    // Remove from list
    connectedDevices.removeWhere((d) => d.id == device.id);
    Get.log("Disconnected device ${device.deviceName}");
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  @override
  void onClose() {
    stopScan();
    scanSubscription?.cancel();
    super.onClose();
  }
}
