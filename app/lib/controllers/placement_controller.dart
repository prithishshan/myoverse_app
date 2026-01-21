import 'package:get/get.dart';

class Placement {
  final String id;
  final String title;
  final String imageUrl;
  final String directions;

  const Placement({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.directions,
  });
}

const List<Placement> placements = [
  Placement(
    id: 'shoulder',
    title: 'Shoulder',
    imageUrl: 'assets/patch_placement/shoulder.png',
    directions: 'Place the patch on the upper part of your shoulder, ensuring it is securely attached to the skin.',
  ),
  Placement(
    id: 'leg',
    title: 'Leg',
    imageUrl: 'assets/patch_placement/leg.png',
    directions: 'Place the patch on the top side of your leg about two inches above your knee, ensuring it is securely attached to the skin.',
  ),
  Placement(
    id: 'wrist',
    title: 'Wrist',
    imageUrl: 'assets/patch_placement/wrist.png',
    directions: 'Place the patch on the back of your wrist, ensuring it is securely attached to the skin.',
  ),
];

class PlacementController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  final placementSelected = Rxn<Placement>();

  void onClose() {
    super.onClose();
  }
}