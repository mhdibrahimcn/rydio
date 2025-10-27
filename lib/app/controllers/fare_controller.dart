import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/fare_model.dart';
import '../models/ride_option.dart';
import '../services/uber_service.dart';
import 'location_controller.dart';
import 'uber_auth_controller.dart';

class FareController extends GetxController {
  // Reactive variables
  final RxList<FareModel> fares = <FareModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<RideOption> selectedFilter = RideOption.all.obs;
  final RxBool isRefreshing = false.obs;

  // Location controller reference
  late final LocationController locationController;
  late final UberAuthController uberAuthController;

  @override
  void onInit() {
    super.onInit();
    locationController = Get.find<LocationController>();
    uberAuthController = Get.find<UberAuthController>();
  }

  // Fetch fares from all services
  Future<void> fetchAllFares() async {
    if (!locationController.canSearchFares) {
      Get.snackbar(
        'Missing Information',
        'Please select both pickup and drop locations',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    error.value = '';
    fares.clear();

    try {
      // Ensure we have a valid Uber access token
      final accessToken = await uberAuthController.ensureAccessToken();

      final pickupCoords = locationController.getPickupCoordinates();
      final dropCoords = locationController.getDropCoordinates();

      if (pickupCoords == null || dropCoords == null) {
        throw Exception('Invalid location coordinates');
      }

      final uberFares = await _fetchServiceFares(
        'Uber',
        () => UberService.getRideEstimates(
          fromLat: pickupCoords['lat']!,
          fromLng: pickupCoords['lng']!,
          toLat: dropCoords['lat']!,
          toLng: dropCoords['lng']!,
          accessToken: accessToken,
        ),
      );

      if (uberFares.isEmpty) {
        Get.snackbar(
          'No fares available',
          'We could not retrieve fares right now. Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Sort by price and mark best price
      _processFares(uberFares);

      // Navigate to results page
      Get.toNamed('/fare-results');
    } catch (e, stack) {
      error.value = e.toString();
      debugPrint('Failed to fetch fares: $e');
      debugPrintStack(stackTrace: stack);
      Get.snackbar(
        'Error',
        'Failed to fetch fares. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh fares
  Future<void> refreshFares() async {
    isRefreshing.value = true;
    await fetchAllFares();
    isRefreshing.value = false;
  }

  // Retry on error
  Future<void> retry() async {
    await fetchAllFares();
  }

  // Set filter
  void setFilter(RideOption filter) {
    selectedFilter.value = filter;
  }

  Future<List<FareModel>> _fetchServiceFares(
    String serviceName,
    Future<List<FareModel>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (error, stack) {
      debugPrint('[$serviceName] fare fetch failed: $error');
      debugPrintStack(stackTrace: stack);
      return const <FareModel>[];
    }
  }

  // Get filtered fares
  List<FareModel> get filteredFares {
    if (selectedFilter.value == RideOption.all) {
      return fares;
    }

    return fares.where((fare) {
      switch (selectedFilter.value) {
        case RideOption.bikes:
          return fare.category == CabType.bike;
        case RideOption.autos:
          return fare.category == CabType.auto;
        case RideOption.cabs:
          return fare.category == CabType.cab || fare.category == CabType.pool;
        default:
          return true;
      }
    }).toList();
  }

  // Get cheapest fare
  FareModel? get cheapestFare {
    if (fares.isEmpty) return null;
    return fares.reduce((a, b) => a.price < b.price ? a : b);
  }

  // Get fastest fare
  FareModel? get fastestFare {
    if (fares.isEmpty) return null;
    return fares.reduce((a, b) => a.eta < b.eta ? a : b);
  }

  // Process and sort fares
  void _processFares(List<FareModel> allFares) {
    // Sort by price
    allFares.sort((a, b) => a.price.compareTo(b.price));

    // Mark best price
    if (allFares.isNotEmpty) {
      allFares.first = FareModel(
        serviceName: allFares.first.serviceName,
        cabType: allFares.first.cabType,
        category: allFares.first.category,
        price: allFares.first.price,
        eta: allFares.first.eta,
        seats: allFares.first.seats,
        isBestPrice: true,
        deepLinkUrl: allFares.first.deepLinkUrl,
      );
    }

    fares.value = allFares;
  }

  // Clear all data
  void clearFares() {
    fares.clear();
    error.value = '';
    selectedFilter.value = RideOption.all;
  }

  // Get fare statistics
  Map<String, dynamic> get fareStats {
    if (fares.isEmpty) {
      return {
        'count': 0,
        'minPrice': 0.0,
        'maxPrice': 0.0,
        'avgPrice': 0.0,
        'minEta': 0,
        'maxEta': 0,
        'avgEta': 0,
      };
    }

    final prices = fares.map((f) => f.price).toList();
    final etas = fares.map((f) => f.eta).toList();

    return {
      'count': fares.length,
      'minPrice': prices.reduce((a, b) => a < b ? a : b),
      'maxPrice': prices.reduce((a, b) => a > b ? a : b),
      'avgPrice': prices.reduce((a, b) => a + b) / prices.length,
      'minEta': etas.reduce((a, b) => a < b ? a : b),
      'maxEta': etas.reduce((a, b) => a > b ? a : b),
      'avgEta': etas.reduce((a, b) => a + b) / etas.length,
    };
  }
}
