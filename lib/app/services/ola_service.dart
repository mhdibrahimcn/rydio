import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class OlaService {
  static const String _baseUrl = AppConstants.olaBaseUrl;

  // Mock implementation - replace with real API calls when keys are available
  static Future<List<FareModel>> getCabEstimates({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Mock data - replace with real API call
    if (ApiKeys.hasOlaKey) {
      return await _getRealEstimates(pickupLat, pickupLng, dropLat, dropLng);
    } else {
      return _getMockEstimates(pickupLat, pickupLng, dropLat, dropLng);
    }
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

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.olaApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOlaResponse(data);
      } else {
        throw Exception('Ola API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      return _getMockEstimates(pickupLat, pickupLng, dropLat, dropLng);
    }
  }

  static List<FareModel> _getMockEstimates(
    double pickupLat,
    double pickupLng,
    double dropLat,
    double dropLng,
  ) {
    final random = Random();
    final basePrice = _calculateBasePrice(
      pickupLat,
      pickupLng,
      dropLat,
      dropLng,
    );

    return [
      FareModel(
        serviceName: ServiceName.ola,
        cabType: 'Ola Mini',
        category: CabType.cab,
        price: basePrice + random.nextInt(40),
        eta: 4 + random.nextInt(8),
        seats: 4,
        deepLinkUrl:
            'oladriver://booking?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$dropLat&drop_lng=$dropLng',
      ),
      FareModel(
        serviceName: ServiceName.ola,
        cabType: 'Ola Micro',
        category: CabType.cab,
        price: basePrice + 20 + random.nextInt(30),
        eta: 5 + random.nextInt(7),
        seats: 4,
        deepLinkUrl:
            'oladriver://booking?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$dropLat&drop_lng=$dropLng',
      ),
      FareModel(
        serviceName: ServiceName.ola,
        cabType: 'Ola Prime Sedan',
        category: CabType.cab,
        price: basePrice + 50 + random.nextInt(40),
        eta: 6 + random.nextInt(9),
        seats: 4,
        deepLinkUrl:
            'oladriver://booking?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$dropLat&drop_lng=$dropLng',
      ),
      FareModel(
        serviceName: ServiceName.ola,
        cabType: 'Ola Auto',
        category: CabType.auto,
        price: basePrice - 15 + random.nextInt(25),
        eta: 3 + random.nextInt(6),
        seats: 3,
        deepLinkUrl:
            'oladriver://booking?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$dropLat&drop_lng=$dropLng',
      ),
    ];
  }

  static List<FareModel> _parseOlaResponse(Map<String, dynamic> data) {
    final List<FareModel> fares = [];

    if (data['ride_estimates'] != null) {
      for (var estimate in data['ride_estimates']) {
        fares.add(
          FareModel(
            serviceName: ServiceName.ola,
            cabType: estimate['category_name'] ?? 'Ola',
            category: _getCategoryFromOlaType(estimate['category']),
            price: (estimate['amount'] ?? 0).toDouble(),
            eta: estimate['eta'] ?? 0,
            seats: _getSeatsFromOlaType(estimate['category']),
            deepLinkUrl:
                estimate['booking_id'] != null
                    ? 'oladriver://booking?id=${estimate['booking_id']}'
                    : null,
          ),
        );
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

  static double _calculateBasePrice(
    double pickupLat,
    double pickupLng,
    double dropLat,
    double dropLng,
  ) {
    // Simple distance calculation for mock pricing
    final distance = _calculateDistance(pickupLat, pickupLng, dropLat, dropLng);
    return distance * 2.2; // ₹2.2 per km base rate
  }

  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
