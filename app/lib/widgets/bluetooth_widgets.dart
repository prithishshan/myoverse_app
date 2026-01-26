import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectedDeviceCard extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onDisconnect;

  const ConnectedDeviceCard({
    super.key,
    required this.device,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 70,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // surfaceColor
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.bluetooth,
                color: Color(0xFFD17A4A), // accentColor
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  device.platformName.isNotEmpty
                      ? device.platformName
                      : "Unknown",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Disconnect button
          GestureDetector(
            onTap: onDisconnect,
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              color: Color(0xFF71717A),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class AddDeviceCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddDeviceCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
          // dotted border would be nice but simple border is fine for now
        ),
        child: const Center(
          child: Icon(CupertinoIcons.add, color: Color(0xFFD17A4A), size: 32),
        ),
      ),
    );
  }
}
