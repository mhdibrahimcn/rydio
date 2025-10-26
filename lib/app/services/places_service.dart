import 'dart:convert';
import 'dart:developer' show log;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class PlacesService {
  // Use OpenStreetMap Nominatim for free location search/details
  static const String _nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String _nominatimDetailsUrl =
      'https://nominatim.openstreetmap.org/details.php';

  // Nominatim policy requires a valid User-Agent identifying the application.
  static const Map<String, String> _defaultHeaders = {
    'User-Agent': 'RydioApp/1.0 (contact: example@conceptmates.com)',
    'Accept': 'application/json',
  };

  // Rate limiting: ensure at least ~1s between requests
  static DateTime? _lastRequestTime;

  // Search for places using Nominatim
  static Future<List<LocationModel>> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    // Enforce simple rate-limit
    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1000) {
        await Future.delayed(const Duration(milliseconds: 1000) - diff);
      }
    }

    final uri = Uri.parse(_nominatimSearchUrl).replace(
      queryParameters: {
        'q': trimmedQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
      },
    );

    try {
      log('PlacesService: GET $uri', name: 'PlacesService.searchPlaces');
      final response = await http.get(uri, headers: _defaultHeaders);
      _lastRequestTime = DateTime.now();

      log(
        'PlacesService: Response ${response.statusCode} ${response.body}',
        name: 'PlacesService.searchPlaces',
      );
      if (response.statusCode != 200) {
        throw PlacesServiceException(
          'Nominatim returned status ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as List<dynamic>;
      final results = <LocationModel>[];

      for (final item in data) {
        final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;

        results.add(
          LocationModel(
            name:
                (item['display_name'] as String?)?.split(',').first ??
                'Unknown',
            address: item['display_name'] ?? '',
            latitude: lat,
            longitude: lon,
            placeId: item['place_id']?.toString(),
          ),
        );
      }

      return results;
    } catch (e) {
      log(
        'PlacesService: Error fetching places for "$trimmedQuery" -> $e',
        name: 'PlacesService.searchPlaces',
      );
      if (e is PlacesServiceException) rethrow;
      throw PlacesServiceException('Failed to search places', e);
    }
  }

  // Get detailed information about a place using place ID (Nominatim details.php)
  static Future<LocationModel?> getPlaceDetails(String placeId) async {
    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1000) {
        await Future.delayed(const Duration(milliseconds: 1000) - diff);
      }
    }

    final uri = Uri.parse(
      _nominatimDetailsUrl,
    ).replace(queryParameters: {'place_id': placeId, 'format': 'json'});

    try {
      log('PlacesService: GET $uri', name: 'PlacesService.getPlaceDetails');
      final response = await http.get(uri, headers: _defaultHeaders);
      _lastRequestTime = DateTime.now();

      log(
        'PlacesService: Response ${response.statusCode} ${response.body}',
        name: 'PlacesService.getPlaceDetails',
      );
      if (response.statusCode != 200) {
        throw PlacesServiceException(
          'Nominatim returned status ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final lat = double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0;
      final lon = double.tryParse(data['lon']?.toString() ?? '0') ?? 0.0;

      return LocationModel(
        name:
            (data['localname'] as String?) ??
            (data['display_name'] as String?) ??
            'Selected Location',
        address: data['display_name'] ?? '',
        latitude: lat,
        longitude: lon,
        placeId: data['place_id']?.toString(),
      );
    } catch (e) {
      log(
        'PlacesService: Error fetching place details for "$placeId" -> $e',
        name: 'PlacesService.getPlaceDetails',
      );
      if (e is PlacesServiceException) rethrow;
      throw PlacesServiceException('Failed to fetch place details', e);
    }
  }

  // Get current location using device GPS
  static Future<LocationModel> getCurrentLocation() async {
    // Ensure GPS services are enabled before requesting the position
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw LocationPermissionException(
        'Location services are disabled. Enable them in settings and try again.',
      );
    }

    // Request runtime permissions when required
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionException(
        'Location permission denied. Grant access to use your current location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw LocationPermissionException(
        'Location permission is permanently denied. Enable it in app settings to continue.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final address =
          placemarks.isNotEmpty
              ? _formatAddress(placemarks.first)
              : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      return LocationModel(
        name: 'Current Location',
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      throw Exception(
        'Failed to determine current location. Please try again.',
      );
    }
  }

  static String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.join(', ');
  }
}

class LocationPermissionException implements Exception {
  LocationPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlacesServiceException implements Exception {
  PlacesServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
