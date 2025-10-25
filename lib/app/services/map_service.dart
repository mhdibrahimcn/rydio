import 'dart:math' as math;

import '../utils/api_keys.dart';
import '../utils/constants.dart';

class MapService {
  // Generate static map URL using Google Static Maps API
  static String getStaticMapUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    int width = 400,
    int height = 200,
  }) {
    if (!ApiKeys.hasGoogleMapsKey) {
      return _getMockMapUrl();
    }

    final baseUrl = '${AppConstants.googleMapsUrl}/staticmap';
    final markers =
        'markers=color:green%7C$originLat,$originLng|markers=color:red%7C$destLat,$destLng';
    final path =
        'path=color:0x00D9FF%7Cweight:3%7C$originLat,$originLng%7C$destLat,$destLng';
    final size = 'size=${width}x$height';
    final key = 'key=${ApiKeys.googleMapsApiKey}';

    return '$baseUrl?$size&$markers&$path&$key';
  }

  // Calculate distance between two points
  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadius = 6371; // km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Calculate estimated travel time (rough approximation)
  static int calculateEstimatedTime({
    required double distance,
    double averageSpeed = 25.0, // km/h average city speed
  }) {
    return (distance / averageSpeed * 60).round(); // minutes
  }

  static String _getMockMapUrl() {
    // Return a placeholder image URL for mock data
    return 'https://via.placeholder.com/400x200/1B263B/00D9FF?text=Map+Preview';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
