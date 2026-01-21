import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/controllers/placement_controller.dart';
import 'package:app/routes/app_routes.dart';

class PatchPlacementPage extends StatelessWidget {
  const PatchPlacementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the controller that was initialized in HomePage
    final PlacementController placementController = Get.find<PlacementController>();

    // Design System Colors
    const Color surfaceColor = Color(0xFF18181B);
    const Color accentColor = Color(0xFFD17A4A);
    const Color textColor = Colors.white;
    const Color subtextColor = Color(0xFF71717A);

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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              final placement = placementController.placementSelected.value;

              if (placement == null) {
                return const Center(
                  child: Text(
                    'No placement selected',
                    style: TextStyle(color: subtextColor),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        placement.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              color: subtextColor,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text Content
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placement.title,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          placement.directions,
                          style: const TextStyle(
                            color: subtextColor,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () {

                        Get.offNamed(AppRoutes.sensorReadout);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Text(
                        'Start Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
