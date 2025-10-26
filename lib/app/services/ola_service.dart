import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class OlaService {
  static const String _baseUrl = AppConstants.olaBaseUrl;

  static Future<List<FareModel>> getCabEstimates({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    if (!ApiKeys.hasOlaKey) {
      const message = 'Ola API credentials are not configured.';
      log(message, name: 'OlaService.getCabEstimates');
      throw OlaServiceException(message);
    }

    log(
      'OlaService: Requesting cab estimates from ($pickupLat, $pickupLng) to ($dropLat, $dropLng)',
      name: 'OlaService.getCabEstimates',
    );

    return _getRealEstimates(pickupLat, pickupLng, dropLat, dropLng);
  }

  static Future<List<FareModel>> _getRealEstimates(
    double pickupLat,
    double pickupLng,
    double dropLat,
    double dropLng,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/create');

      final body = {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
      };

      log(
        'OlaService: POST $url body=$body',
        name: 'OlaService._getRealEstimates',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.olaApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      log(
        'OlaService: Response ${response.statusCode} ${response.body}',
        name: 'OlaService._getRealEstimates',
      );
      if (response.statusCode != 200) {
        throw OlaServiceException('Ola API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return _parseOlaResponse(data);
    } catch (e) {
      log(
        'OlaService: Error fetching Ola estimates -> $e',
        name: 'OlaService._getRealEstimates',
      );
      if (e is OlaServiceException) rethrow;
      throw OlaServiceException('Failed to fetch Ola estimates', e);
    }
  }

  static List<FareModel> _parseOlaResponse(Map<String, dynamic> data) {
    final List<FareModel> fares = [];

    if (data['ride_estimates'] != null) {
      for (var estimate in data['ride_estimates']) {
        if (estimate is! Map<String, dynamic>) {
          continue;
        }

        final fare = _mapEstimateToFare(estimate);
        if (fare != null) {
          fares.add(fare);
        }
      }
    }

    return fares;
  }

  static CabType _getCategoryFromOlaType(String? category) {
    if (category == null) return CabType.cab;

    if (category.toLowerCase().contains('auto')) return CabType.auto;
    if (category.toLowerCase().contains('bike')) return CabType.bike;
    return CabType.cab;
  }

  static int _getSeatsFromOlaType(String? category) {
    if (category == null) return 4;

    if (category.toLowerCase().contains('auto')) return 3;
    if (category.toLowerCase().contains('bike')) return 1;
    return 4;
  }

  static FareModel? _mapEstimateToFare(Map<String, dynamic> estimate) {
    final amount = _toDouble(estimate['amount'] ?? estimate['fare_estimate']);

    if (amount == null) {
      log(
        'OlaService: Skipping estimate without usable fare: $estimate',
        name: 'OlaService._mapEstimateToFare',
      );
      return null;
    }

    final cabType = estimate['category_name'] ?? estimate['category'] ?? 'Ola';
    final eta = _secondsToMinutes(estimate['eta']);
    final category = _getCategoryFromOlaType(estimate['category']?.toString());
    final seats = _getSeatsFromOlaType(estimate['category']?.toString());

    return FareModel(
      serviceName: ServiceName.ola,
      cabType: cabType.toString(),
      category: category,
      price: amount,
      eta: eta,
      seats: seats,
      deepLinkUrl: estimate['booking_url']?.toString(),
    );
  }

  static int _secondsToMinutes(dynamic value) {
    final seconds = _toDouble(value);
    if (seconds == null) return 0;
    return (seconds / 60).ceil();
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }
}

class OlaServiceException implements Exception {
  OlaServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
