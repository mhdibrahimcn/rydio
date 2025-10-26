import 'dart:developer' show log;
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
      const message = 'Google Maps Static API key is not configured.';
      log(message, name: 'MapService.getStaticMapUrl');
      throw MapServiceException(message);
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

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

class MapServiceException implements Exception {
  MapServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
