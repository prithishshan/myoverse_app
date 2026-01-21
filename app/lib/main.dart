import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app/routes/app_pages.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetCupertinoApp(
      title: 'Myo App',
      theme: const CupertinoThemeData(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
