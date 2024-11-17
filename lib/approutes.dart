import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:skin_detection_app/page/HomePage.dart';
import 'package:skin_detection_app/page/SkinconditionDetailPage/SkinConditionDetail.dart';

class AppPages {
  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: Routes.home,
      page: () => const Homepage(),
    ),
    GetPage(
      name: Routes.skinConditionDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final conditionName = args?['condition'] as String? ?? '';
        return SkinConditionDetail(conditionName: conditionName);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}

abstract class Routes {
  static const home = '/';
  static const skinConditionDetail = '/skin-condition/:condition';

  // Helper method to generate the skin condition detail route
  static String skinConditionDetailPath(String condition) => '/skin-condition/$condition';
}

// Extension to make navigation easier
extension AppNavigation on GetInterface {
  Future<T?>? toSkinConditionDetail<T>(String conditionName) {
    return toNamed<T>(
      Routes.skinConditionDetailPath(Uri.encodeComponent(conditionName)),
      arguments: {'condition': conditionName},
    );
  }
}