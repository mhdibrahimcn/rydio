import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class RapidoService {
  static const String _baseUrl = AppConstants.rapidoBaseUrl;

  static Future<List<FareModel>> getBikeEstimates({
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) async {
    if (!ApiKeys.hasRapidoKey) {
      const message = 'Rapido API credentials are not configured.';
      log(message, name: 'RapidoService.getBikeEstimates');
      throw RapidoServiceException(message);
    }

    log(
      'RapidoService: Requesting ride estimates from ($sourceLat, $sourceLng) to ($destLat, $destLng)',
      name: 'RapidoService.getBikeEstimates',
    );

    return _getRealEstimates(sourceLat, sourceLng, destLat, destLng);
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

      log(
        'RapidoService: POST $url body=$body',
        name: 'RapidoService._getRealEstimates',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.rapidoApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      log(
        'RapidoService: Response ${response.statusCode} ${response.body}',
        name: 'RapidoService._getRealEstimates',
      );
      if (response.statusCode != 200) {
        throw RapidoServiceException(
          'Rapido API error: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body);
      return _parseRapidoResponse(data);
    } catch (e) {
      log(
        'RapidoService: Error fetching Rapido estimates -> $e',
        name: 'RapidoService._getRealEstimates',
      );
      if (e is RapidoServiceException) rethrow;
      throw RapidoServiceException('Failed to fetch Rapido estimates', e);
    }
  }

  static List<FareModel> _parseRapidoResponse(Map<String, dynamic> data) {
    final List<FareModel> fares = [];

    if (data['estimates'] != null) {
      for (var estimate in data['estimates']) {
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

  static FareModel? _mapEstimateToFare(Map<String, dynamic> estimate) {
    final fare = _toDouble(estimate['fare'] ?? estimate['total_amount']);

    if (fare == null) {
      log(
        'RapidoService: Skipping estimate without usable fare: $estimate',
        name: 'RapidoService._mapEstimateToFare',
      );
      return null;
    }

    final cabType = estimate['vehicle_type']?.toString() ?? 'Rapido';
    final category = _getCategoryFromRapidoType(estimate['vehicle_type']);
    final seats = _getSeatsFromRapidoType(estimate['vehicle_type']);
    final eta = _secondsToMinutes(estimate['eta']);

    return FareModel(
      serviceName: ServiceName.rapido,
      cabType: cabType,
      category: category,
      price: fare,
      eta: eta,
      seats: seats,
      deepLinkUrl: estimate['deep_link']?.toString(),
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

class RapidoServiceException implements Exception {
  RapidoServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
