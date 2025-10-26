import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../controllers/fare_controller.dart';
import '../controllers/ui_controller.dart';
import '../controllers/uber_auth_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize controllers
    Get.lazyPut<LocationController>(() => LocationController());
    Get.lazyPut<UberAuthController>(() => UberAuthController());
    Get.lazyPut<FareController>(() => FareController());
    Get.lazyPut<UIController>(() => UIController());
  }
}
