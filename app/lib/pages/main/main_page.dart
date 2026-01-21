import 'package:flutter/cupertino.dart';
import 'package:app/pages/analytics/analytics_page.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/settings/settings_page.dart';
import 'package:app/controllers/bluetooth_controller.dart';
import 'package:app/controllers/placement_controller.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BluetoothController());
    Get.put(PlacementController());

    return CupertinoTabScaffold(
      controller: CupertinoTabController(initialIndex: 1),
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF18181B), // surfaceColor
        activeColor: const Color(0xFFD17A4A), // accentColor
        inactiveColor: const Color(0xFF71717A), // subtextColor
        height: 60,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_square),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => const AnalyticsPage(),
            );
          case 1:
            return CupertinoTabView(builder: (context) => const HomePage());
          case 2:
            return CupertinoTabView(builder: (context) => const SettingsPage());
          default:
            return CupertinoTabView(builder: (context) => const HomePage());
        }
      },
    );
  }
}
