import 'package:app/widgets/pose_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:app/controllers/graph_controller.dart';
import 'package:flutter/material.dart' show Colors;

class SensorReadoutPage extends StatefulWidget {
  const SensorReadoutPage({super.key});

  @override
  State<SensorReadoutPage> createState() => _SensorReadoutPageState();
}

class _SensorReadoutPageState extends State<SensorReadoutPage> {
  // Colors from the design (matching home_page.dart)
  static const Color backgroundColor = Color(0xFF000000); // bg-black
  static const Color surfaceColor = Color(0xFF18181B); // bg-zinc-900
  static const Color cardBorderColor = Color(0xFF3F3F46); // border-zinc-800
  static const Color accentColor = Color(0xFFD17A4A);
  static const Color borderColor = Color(0xFF27272A); // border-zinc-900 (approx)
  static const Color textColor = Colors.white;
  static const Color subtextColor = Color(0xFF71717A); // text-zinc-500
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(primaryColor: accentColor),
      child: CupertinoPageScaffold(
        backgroundColor: Colors.black,
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Colors.black,
          middle: Text('Patch Placement', style: TextStyle(color: textColor)),
          previousPageTitle: 'Home',
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 24)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 200,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SensorLineGraph(
                    stream: Stream<double>.periodic(
                      const Duration(milliseconds: 5),
                      (count) => (count % 100) / 100.0 * 2 - 1,
                    ),
                    hz: 200,
                    windowSeconds: 5,
                    repaintFps: 60,
                    strokeWidth: 2,
                    padding: const EdgeInsets.all(12),
                    fixedMin: -1.0,
                    fixedMax: 1.0,
                    lineColor: accentColor,
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 24)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 200,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PoseWidget()
              ),
              )
            ],
          ),
        ),
      )
    );
  }
}
