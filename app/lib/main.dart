import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/controllers/settings_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.put(SettingsController());

    return Obx(
      () => GetCupertinoApp(
        title: 'Myo App',
        theme: settingsController.currentTheme.value,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
