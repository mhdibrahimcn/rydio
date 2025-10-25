import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class UberService {
  static String get _baseUrl =>
      ApiKeys.useUberSandbox
          ? AppConstants.uberSandboxBaseUrl
          : AppConstants.uberBaseUrl;

  // Mock implementation - replace with real API calls when keys are available
  static Future<List<FareModel>> getRideEstimates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data - replace with real API call
    if (ApiKeys.hasUberKeys) {
      return await _getRealEstimates(fromLat, fromLng, toLat, toLng);
    } else {
      return _getMockEstimates(fromLat, fromLng, toLat, toLng);
    }
  }

  static Future<List<FareModel>> _getRealEstimates(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/estimates/price?start_latitude=$fromLat&start_longitude=$fromLng&end_latitude=$toLat&end_longitude=$toLng',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token ${ApiKeys.uberServerToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseUberResponse(data);
      } else {
        throw Exception('Uber API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      return _getMockEstimates(fromLat, fromLng, toLat, toLng);
    }
  }

  static List<FareModel> _getMockEstimates(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final random = Random();
    final basePrice = _calculateBasePrice(fromLat, fromLng, toLat, toLng);

    return [
      FareModel(
        serviceName: ServiceName.uber,
        cabType: 'UberGo',
        category: CabType.cab,
        price: basePrice + random.nextInt(50),
        eta: 5 + random.nextInt(10),
        seats: 4,
        deepLinkUrl:
            'uber://?action=setPickup&pickup[latitude]=$fromLat&pickup[longitude]=$fromLng&dropoff[latitude]=$toLat&dropoff[longitude]=$toLng',
      ),
      FareModel(
        serviceName: ServiceName.uber,
        cabType: 'UberX',
        category: CabType.cab,
        price: basePrice + 30 + random.nextInt(50),
        eta: 6 + random.nextInt(8),
        seats: 4,
        deepLinkUrl:
            'uber://?action=setPickup&pickup[latitude]=$fromLat&pickup[longitude]=$fromLng&dropoff[latitude]=$toLat&dropoff[longitude]=$toLng',
      ),
      FareModel(
        serviceName: ServiceName.uber,
        cabType: 'UberPool',
        category: CabType.pool,
        price: basePrice - 20 + random.nextInt(30),
        eta: 8 + random.nextInt(12),
        seats: 2,
        deepLinkUrl:
            'uber://?action=setPickup&pickup[latitude]=$fromLat&pickup[longitude]=$fromLng&dropoff[latitude]=$toLat&dropoff[longitude]=$toLng',
      ),
      FareModel(
        serviceName: ServiceName.uber,
        cabType: 'UberXL',
        category: CabType.cab,
        price: basePrice + 60 + random.nextInt(40),
        eta: 7 + random.nextInt(10),
        seats: 6,
        deepLinkUrl:
            'uber://?action=setPickup&pickup[latitude]=$fromLat&pickup[longitude]=$fromLng&dropoff[latitude]=$toLat&dropoff[longitude]=$toLng',
      ),
    ];
  }

  static List<FareModel> _parseUberResponse(Map<String, dynamic> data) {
    final List<FareModel> fares = [];

    if (data['prices'] != null) {
      for (var price in data['prices']) {
        fares.add(
          FareModel(
            serviceName: ServiceName.uber,
            cabType: price['display_name'] ?? 'Uber',
            category: _getCategoryFromUberType(price['product_id']),
            price: (price['estimate'] ?? 0).toDouble(),
            eta: price['duration'] ?? 0,
            seats: _getSeatsFromUberType(price['product_id']),
            deepLinkUrl:
                price['product_id'] != null
                    ? 'uber://?action=setPickup&pickup[latitude]=${price['start_latitude']}&pickup[longitude]=${price['start_longitude']}&dropoff[latitude]=${price['end_latitude']}&dropoff[longitude]=${price['end_longitude']}'
                    : null,
          ),
        );
      }
    }

    return fares;
  }

  static CabType _getCategoryFromUberType(String? productId) {
    if (productId == null) return CabType.cab;

    if (productId.contains('pool')) return CabType.pool;
    if (productId.contains('xl')) return CabType.cab;
    return CabType.cab;
  }

  static int _getSeatsFromUberType(String? productId) {
    if (productId == null) return 4;

    if (productId.contains('xl')) return 6;
    if (productId.contains('pool')) return 2;
    return 4;
  }

  static double _calculateBasePrice(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    // Simple distance calculation for mock pricing
    final distance = _calculateDistance(fromLat, fromLng, toLat, toLng);
    return distance * 2.5; // ₹2.5 per km base rate
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
