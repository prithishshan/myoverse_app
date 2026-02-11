import 'dart:async';
import 'dart:math' as math;

import 'package:app/widgets/bilateral_muscle_widget.dart';
import 'package:app/widgets/muscle_widget.dart';
// import 'package:app/experiements/sensor_array_widget.dart';
import 'package:flutter/cupertino.dart';
// import 'package:app/controllers/graph_controller.dart';
import 'package:flutter/material.dart' show Colors;

class SensorReadoutPage extends StatefulWidget {
  const SensorReadoutPage({super.key});

  @override
  State<SensorReadoutPage> createState() => _SensorReadoutPageState();
}

class _SensorReadoutPageState extends State<SensorReadoutPage> {
  static const Color backgroundColor = Color(0xFF000000); // bg-black
  static const Color surfaceColor = Color(0xFF18181B); // bg-zinc-900

  static const Color accentColor = Color(0xFFD17A4A);
  static const Color textColor = Colors.white;

  // 6 Simulators for Raw Data
  final List<StreamController<double>> _rawControllers = [];
  final List<Stream<double>> _rawStreams = [];

  // 3 Simulators for Averaged Data (MuscleWidget Rings)
  final List<StreamController<double>> _avgControllers = [];
  final List<Stream<double>> _avgStreams = [];

  // 2 Simulators for Side Averaged Data (Bilateral Widget)
  final List<StreamController<double>> _sideAvgControllers = [];
  final List<Stream<double>> _sideAvgStreams = [];

  Timer? _simTimer;

  // Phase offsets for simulation (12 sensors)
  final List<double> _phases = List.filled(12, 0.0);
  final List<double> _speeds = List.filled(12, 1.0);

  int _selectedView = 0; // 0:Avg, 1:Mus, 2:Raw, 3:Neu, 4:Arr, 5:Bi

  @override
  void initState() {
    super.initState();
    _initStreams();
    _startSimulation();
  }

  void _initStreams() {
    // 1. Setup 12 Raw Streams (0-5 Left, 6-11 Right)
    for (int i = 0; i < 12; i++) {
      final controller = StreamController<double>.broadcast();
      _rawControllers.add(controller);
      _rawStreams.add(controller.stream);
    }

    // 2. Setup 3 Avg Streams (Existing)
    for (int i = 0; i < 3; i++) {
      final controller = StreamController<double>.broadcast();
      _avgControllers.add(controller);
      _avgStreams.add(controller.stream);
    }

    // 3. Setup 2 Side Avg Streams (New)
    for (int i = 0; i < 2; i++) {
      final controller = StreamController<double>.broadcast();
      _sideAvgControllers.add(controller);
      _sideAvgStreams.add(controller.stream);
    }

    final random = math.Random();
    for (int i = 0; i < 12; i++) {
      _phases[i] = random.nextDouble() * 2 * math.pi;
      _speeds[i] = 1.0 + random.nextDouble() * 2.0;
    }
  }

  void _startSimulation() {
    // Defines simulation tick rate (e.g. 50 inputs per second)
    const duration = Duration(milliseconds: 20);
    int tick = 0;

    _simTimer = Timer.periodic(duration, (_) {
      tick++;
      final List<double> currentRawValues = [];
      final math.Random random = math.Random();

      // Baselines for the 12 sensors
      // Left (0-5) + Right (6-11)
      final List<double> baselines = [
        0.2, 0.22, 0.6, 0.58, 0.45, 0.42, // Left
        0.2, 0.22, 0.6, 0.58, 0.45, 0.42, // Right (Mirrored)
      ];

      // Generate 12 raw values
      for (int i = 0; i < 12; i++) {
        double t = (tick * 0.05) * _speeds[i] + _phases[i];
        double wave = (math.sin(t) + 0.3 * math.sin(t * 2.5));
        double amplitude = 0.15;
        double noise = (random.nextDouble() - 0.5) * 0.05;
        double val = baselines[i] + (wave * amplitude) + noise;
        val = val.clamp(0.0, 1.0);

        currentRawValues.add(val);
        if (!_rawControllers[i].isClosed) {
          _rawControllers[i].add(val);
        }
      }

      // Generate 3 averaged values (Standard) - Using Left Side Only for Demo? Or Mix?
      // Let's use Left Side (0-5) for standard Averaged Graph
      for (int i = 0; i < 3; i++) {
        final avg = (currentRawValues[i * 2] + currentRawValues[i * 2 + 1]) / 2;
        if (!_avgControllers[i].isClosed) {
          _avgControllers[i].add(avg);
        }
      }

      // Generate 2 Side Averaged Values (Left vs Right)
      double leftSum = 0;
      for (int i = 0; i < 6; i++) leftSum += currentRawValues[i];
      double rightSum = 0;
      for (int i = 6; i < 12; i++) rightSum += currentRawValues[i];

      if (!_sideAvgControllers[0].isClosed)
        _sideAvgControllers[0].add(leftSum / 6.0);
      if (!_sideAvgControllers[1].isClosed)
        _sideAvgControllers[1].add(rightSum / 6.0);
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    for (var c in _rawControllers) c.close();
    for (var c in _avgControllers) c.close();
    for (var c in _sideAvgControllers) c.close();
    super.dispose();
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
              // const SizedBox(height: 16),
              // View Selector
              // SizedBox(
              //   width: double.infinity,
              //   child: CupertinoSlidingSegmentedControl<int>(
              //     groupValue: _selectedView,
              //     thumbColor: surfaceColor,
              //     backgroundColor: Colors.white10,
              //     children: const {
              //       0: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Avg",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //       1: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Mus",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //       2: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Raw",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //       3: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Neu",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //       4: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Arr",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //       5: Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 8),
              //         child: Text(
              //           "Bi",
              //           style: TextStyle(color: textColor, fontSize: 13),
              //         ),
              //       ),
              //     },
              //     onValueChanged: (val) {
              //       if (val != null) setState(() => _selectedView = val);
              //     },
              //   ),
              // ),
              const SizedBox(height: 96),

              // View Body
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // switch (_selectedView) {
    //   case 0:
    // 1. Averaged Graph
    //   return Center(
    //     child: Container(
    //       margin: const EdgeInsets.symmetric(horizontal: 24),
    //       height: 200,
    //       decoration: BoxDecoration(
    //         color: surfaceColor,
    //         borderRadius: BorderRadius.circular(16),
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.black.withOpacity(0.2),
    //             blurRadius: 10,
    //             offset: const Offset(0, 4),
    //           ),
    //         ],
    //       ),
    //       child: ClipRRect(
    //         borderRadius: BorderRadius.circular(16),
    //         child: SensorLineGraph(
    //           streams: _avgStreams,
    //           hz: 50,
    //           windowSeconds: 2,
    //           repaintFps: 20,
    //           strokeWidth: 2,
    //           padding: const EdgeInsets.all(12),
    //           fixedMin: 0.0,
    //           fixedMax: 1.0,
    //           lineColors: const [
    //             Color(0xFFFF4081),
    //             Color(0xFF9C27B0),
    //             Color(0xFF00E5FF),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // case 1:
    // 2. Main Muscle Widget
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 300,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: AspectRatio(
          aspectRatio: 1,
          child: AspectRatio(
            aspectRatio: 1,
            child: MuscleWidget(
              streams: _rawStreams,
              avgStreams: _avgStreams,
              showRings: true,
              // imageAsset: 'assets/body_model/shoulder.png',
              // svgAsset: null,
              muscleId: null,
            ),
          ),
        ),
      ),
    );
    // case 2:
    //   // 3. Raw Graph
    //   return Center(
    //     child: Container(
    //       margin: const EdgeInsets.symmetric(horizontal: 24),
    //       height: 200,
    //       decoration: BoxDecoration(
    //         color: surfaceColor,
    //         borderRadius: BorderRadius.circular(16),
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.black.withOpacity(0.2),
    //             blurRadius: 10,
    //             offset: const Offset(0, 4),
    //           ),
    //         ],
    //       ),
    //       child: ClipRRect(
    //         borderRadius: BorderRadius.circular(16),
    //         child: SensorLineGraph(
    //           streams: _rawStreams,
    //           hz: 50,
    //           windowSeconds: 2,
    //           repaintFps: 20,
    //           strokeWidth: 1.5,
    //           padding: const EdgeInsets.all(12),
    //           fixedMin: 0.0,
    //           fixedMax: 1.0,
    //           lineColors: const [
    //             Color(0xFFFF4081),
    //             Color(0xFFFF80AB),
    //             Color(0xFF9C27B0),
    //             Color(0xFFE040FB),
    //             Color(0xFF00E5FF),
    //             Color(0xFF84FFFF),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // case 3:
    //   // 4. Neutral Muscle Widget
    //   return Center(
    //     child: Container(
    //       margin: const EdgeInsets.symmetric(horizontal: 24),
    //       height: 300,
    //       decoration: const BoxDecoration(color: Colors.transparent),
    //       child: AspectRatio(
    //         aspectRatio: 1,
    //         child: Obx(() {
    //           final placement = placementController.placementSelected.value;
    //           final isSvg = placement?.imageUrl.endsWith('.svg') ?? false;
    //           return MuscleWidget(
    //             streams: _rawStreams,
    //             avgStreams: const [],
    //             showRings: false,
    //             imageAsset:
    //                 placement?.imageUrl ??
    //                 'assets/body_model/shoulder_neutral.png',
    //             svgAsset: isSvg ? placement?.imageUrl : null,
    //             muscleId: placement?.id,
    //           );
    //         }),
    //       ),
    //     ),
    //   );
    // case 4:
    //   // 5. Sensor Array
    //   return Center(
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         const Text(
    //           "Sensor Array Heatmap",
    //           style: TextStyle(color: Colors.white54),
    //         ),
    //         const SizedBox(height: 16),
    //         SensorArrayWidget(streams: _rawStreams),
    //       ],
    //     ),
    //   );
    // case 5:
    //   // 6. Bilateral Widget
    //   return Center(
    //     child: Container(
    //       margin: const EdgeInsets.symmetric(horizontal: 16),
    //       height: 400,
    //       decoration: const BoxDecoration(color: Colors.transparent),
    //       child: BilateralMuscleWidget(
    //         streams: _rawStreams,
    //         avgStreams: _sideAvgStreams,
    //       ),
    //     ),
    //   );
    // default:
    //   return const SizedBox();
    // }
  }
}
