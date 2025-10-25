import 'package:get/get.dart';
import '../models/location_model.dart';
import '../services/places_service.dart';

class LocationController extends GetxController {
  // Reactive variables
  final Rx<LocationModel?> pickupLocation = Rx<LocationModel?>(null);
  final Rx<LocationModel?> dropLocation = Rx<LocationModel?>(null);
  final RxList<LocationModel> searchResults = <LocationModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingCurrentLocation = false.obs;

  // Search functionality
  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    try {
      final results = await PlacesService.searchPlaces(query);
      searchResults.value = results;
    } catch (e) {
      Get.snackbar(
        'Search Error',
        'Failed to search locations: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Select location for pickup or drop
  Future<void> selectLocation(LocationModel location, bool isPickup) async {
    try {
      // If location doesn't have coordinates, get place details
      if (location.latitude == 0.0 &&
          location.longitude == 0.0 &&
          location.placeId != null) {
        final detailedLocation = await PlacesService.getPlaceDetails(
          location.placeId!,
        );
        if (detailedLocation != null) {
          location = detailedLocation;
        }
      }

      if (isPickup) {
        pickupLocation.value = location;
      } else {
        dropLocation.value = location;
      }

      // Clear search results
      searchResults.clear();

      // Close any open bottom sheets
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to select location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Get current location
  Future<void> getCurrentLocation({
    bool closeSheet = true,
    bool showErrorMessages = true,
  }) async {
    if (isLoadingCurrentLocation.value) {
      return;
    }

    isLoadingCurrentLocation.value = true;

    try {
      final currentLocation = await PlacesService.getCurrentLocation();
      pickupLocation.value = currentLocation;

      if (closeSheet && Get.isBottomSheetOpen == true) {
        Get.back();
      }
    } catch (e) {
      if (showErrorMessages) {
        Get.snackbar(
          'Location Error',
          _formatErrorMessage(e),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingCurrentLocation.value = false;
    }
  }

  // Swap pickup and drop locations
  void swapLocations() {
    final temp = pickupLocation.value;
    pickupLocation.value = dropLocation.value;
    dropLocation.value = temp;
  }

  // Clear locations
  void clearPickupLocation() {
    pickupLocation.value = null;
  }

  void clearDropLocation() {
    dropLocation.value = null;
  }

  // Validation
  bool get hasBothLocations =>
      pickupLocation.value != null && dropLocation.value != null;

  bool get canSearchFares => hasBothLocations;

  // Get formatted location string
  String getPickupDisplayText() {
    if (pickupLocation.value == null) return 'Select pickup location';
    return pickupLocation.value!.name;
  }

  String getDropDisplayText() {
    if (dropLocation.value == null) return 'Select drop location';
    return dropLocation.value!.name;
  }

  // Get location coordinates for API calls
  Map<String, double>? getPickupCoordinates() {
    if (pickupLocation.value == null) return null;
    return {
      'lat': pickupLocation.value!.latitude,
      'lng': pickupLocation.value!.longitude,
    };
  }

  Map<String, double>? getDropCoordinates() {
    if (dropLocation.value == null) return null;
    return {
      'lat': dropLocation.value!.latitude,
      'lng': dropLocation.value!.longitude,
    };
  }

  @override
  void onReady() {
    super.onReady();
    getCurrentLocation(closeSheet: false);
  }

  String _formatErrorMessage(Object error) {
    final message = error.toString();
    const exceptionPrefix = 'Exception: ';
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }
    return message;
  }
}
