import 'package:get/get.dart';
import 'package:app/routes/app_routes.dart';
import 'package:app/pages/home/home_page.dart';
import 'package:app/pages/settings/settings_page.dart';
import 'package:app/pages/analytics/analytics_page.dart';
// import 'package:app/experiements/sensor_readout/sensor_readout_page.dart';
// import 'package:app/experiements/patch_placement/patch_placement_page.dart';
import 'package:app/pages/main/main_page.dart';

class AppPages {
  static const initial = AppRoutes.main;

  static final routes = [
    GetPage(name: AppRoutes.home, page: () => HomePage()),
    GetPage(name: AppRoutes.settings, page: () => SettingsPage()),
    GetPage(name: AppRoutes.analytics, page: () => AnalyticsPage()),
    // GetPage(name: AppRoutes.patchPlacement, page: () => PatchPlacementPage()),
    // GetPage(name: AppRoutes.sensorReadout, page: () => SensorReadoutPage()),
    GetPage(name: AppRoutes.main, page: () => MainPage()),
  ];
}
