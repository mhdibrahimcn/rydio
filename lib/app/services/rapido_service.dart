import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class RapidoService {
  static const String _baseUrl = AppConstants.rapidoBaseUrl;

  // Mock implementation - replace with real API calls when keys are available
  static Future<List<FareModel>> getBikeEstimates({
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock data - replace with real API call
    if (ApiKeys.hasRapidoKey) {
      return await _getRealEstimates(sourceLat, sourceLng, destLat, destLng);
    } else {
      return _getMockEstimates(sourceLat, sourceLng, destLat, destLng);
    }
  }

  static Future<List<FareModel>> _getRealEstimates(
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/estimate');

      final body = {
        'source_lat': sourceLat,
        'source_lng': sourceLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.rapidoApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRapidoResponse(data);
      } else {
        throw Exception('Rapido API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      return _getMockEstimates(sourceLat, sourceLng, destLat, destLng);
    }
  }

  static List<FareModel> _getMockEstimates(
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng,
  ) {
    final random = Random();
    final basePrice = _calculateBasePrice(
      sourceLat,
      sourceLng,
      destLat,
      destLng,
    );

    return [
      FareModel(
        serviceName: ServiceName.rapido,
        cabType: 'Rapido Bike',
        category: CabType.bike,
        price: basePrice - 30 + random.nextInt(20),
        eta: 3 + random.nextInt(5),
        seats: 1,
        deepLinkUrl:
            'rapido://booking?source_lat=$sourceLat&source_lng=$sourceLng&dest_lat=$destLat&dest_lng=$destLng',
      ),
      FareModel(
        serviceName: ServiceName.rapido,
        cabType: 'Rapido Auto',
        category: CabType.auto,
        price: basePrice - 10 + random.nextInt(25),
        eta: 4 + random.nextInt(6),
        seats: 3,
        deepLinkUrl:
            'rapido://booking?source_lat=$sourceLat&source_lng=$sourceLng&dest_lat=$destLat&dest_lng=$destLng',
      ),
      FareModel(
        serviceName: ServiceName.rapido,
        cabType: 'Rapido Cab Non AC',
        category: CabType.cab,
        price: basePrice + 10 + random.nextInt(30),
        eta: 5 + random.nextInt(8),
        seats: 4,
        deepLinkUrl:
            'rapido://booking?source_lat=$sourceLat&source_lng=$sourceLng&dest_lat=$destLat&dest_lng=$destLng',
      ),
      FareModel(
        serviceName: ServiceName.rapido,
        cabType: 'Rapido Cab AC',
        category: CabType.cab,
        price: basePrice + 25 + random.nextInt(35),
        eta: 6 + random.nextInt(9),
        seats: 4,
        deepLinkUrl:
            'rapido://booking?source_lat=$sourceLat&source_lng=$sourceLng&dest_lat=$destLat&dest_lng=$destLng',
      ),
    ];
  }

  static List<FareModel> _parseRapidoResponse(Map<String, dynamic> data) {
    final List<FareModel> fares = [];

    if (data['estimates'] != null) {
      for (var estimate in data['estimates']) {
        fares.add(
          FareModel(
            serviceName: ServiceName.rapido,
            cabType: estimate['vehicle_type'] ?? 'Rapido',
            category: _getCategoryFromRapidoType(estimate['vehicle_type']),
            price: (estimate['fare'] ?? 0).toDouble(),
            eta: estimate['eta'] ?? 0,
            seats: _getSeatsFromRapidoType(estimate['vehicle_type']),
            deepLinkUrl:
                estimate['booking_id'] != null
                    ? 'rapido://booking?id=${estimate['booking_id']}'
                    : null,
          ),
        );
      }
    }

    return fares;
  }

  static CabType _getCategoryFromRapidoType(String? vehicleType) {
    if (vehicleType == null) return CabType.bike;

    if (vehicleType.toLowerCase().contains('bike')) return CabType.bike;
    if (vehicleType.toLowerCase().contains('auto')) return CabType.auto;
    if (vehicleType.toLowerCase().contains('cab')) return CabType.cab;
    return CabType.bike;
  }

  static int _getSeatsFromRapidoType(String? vehicleType) {
    if (vehicleType == null) return 1;

    if (vehicleType.toLowerCase().contains('bike')) return 1;
    if (vehicleType.toLowerCase().contains('auto')) return 3;
    if (vehicleType.toLowerCase().contains('cab')) return 4;
    return 1;
  }

  static double _calculateBasePrice(
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng,
  ) {
    // Simple distance calculation for mock pricing
    final distance = _calculateDistance(sourceLat, sourceLng, destLat, destLng);
    return distance * 1.8; // ₹1.8 per km base rate (cheaper than others)
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
