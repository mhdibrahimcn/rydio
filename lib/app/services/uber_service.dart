import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import '../models/fare_model.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class UberService {
  static String get _baseUrl =>
      ApiKeys.useUberSandbox
          ? AppConstants.uberSandboxBaseUrl
          : AppConstants.uberBaseUrl;

  static Future<List<FareModel>> getRideEstimates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String accessToken,
  }) async {
    if (accessToken.trim().isEmpty) {
      const message = 'Uber access token is required.';
      log(message, name: 'UberService.getRideEstimates');
      throw UberServiceException(message);
    }

    log(
      'UberService: Requesting ride estimates from ($fromLat, $fromLng) to ($toLat, $toLng)',
      name: 'UberService.getRideEstimates',
    );

    return _getRealEstimates(fromLat, fromLng, toLat, toLng, accessToken);
  }

  static Future<List<FareModel>> _getRealEstimates(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    String accessToken,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/estimates/price?start_latitude=$fromLat&start_longitude=$fromLng&end_latitude=$toLat&end_longitude=$toLng',
      );

      log('UberService: GET $url', name: 'UberService._getRealEstimates');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      log(
        'UberService: Response ${response.statusCode} ${response.body}',
        name: 'UberService._getRealEstimates',
      );
      if (response.statusCode != 200) {
        throw UberServiceException('Uber API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return _parseUberResponse(data, fromLat, fromLng, toLat, toLng);
    } catch (e) {
      log(
        'UberService: Error fetching Uber estimates -> $e',
        name: 'UberService._getRealEstimates',
      );
      if (e is UberServiceException) rethrow;
      throw UberServiceException('Failed to fetch Uber estimates', e);
    }
  }

  static List<FareModel> _parseUberResponse(
    Map<String, dynamic> data,
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final List<FareModel> fares = [];

    if (data['prices'] != null) {
      for (var price in data['prices']) {
        if (price is! Map<String, dynamic>) {
          continue;
        }

        final fare = _mapPriceToFare(price, fromLat, fromLng, toLat, toLng);
        if (fare != null) {
          fares.add(fare);
        }
      }
    }

    return fares;
  }

  static FareModel? _mapPriceToFare(
    Map<String, dynamic> price,
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final displayName =
        price['display_name'] ?? price['localized_display_name'] ?? 'Uber';
    final resolvedPrice = _resolveEstimate(price);

    if (resolvedPrice == null) {
      log(
        'UberService: Skipping price entry without usable estimate: $price',
        name: 'UberService._mapPriceToFare',
      );
      return null;
    }

    final eta = _durationSecondsToMinutes(price['duration']);
    final seats = _resolveCapacity(price);
    final productId = price['product_id']?.toString();

    return FareModel(
      serviceName: ServiceName.uber,
      cabType: displayName.toString(),
      category: _inferCategory(displayName.toString()),
      price: resolvedPrice,
      eta: eta,
      seats: seats,
      deepLinkUrl: _buildDeepLink(productId, fromLat, fromLng, toLat, toLng),
    );
  }

  static double? _resolveEstimate(Map<String, dynamic> price) {
    final low = _toDouble(price['low_estimate']);
    final high = _toDouble(price['high_estimate']);

    if (low != null && high != null) {
      return (low + high) / 2;
    }
    if (low != null) return low;
    if (high != null) return high;

    final estimateRaw = price['estimate']?.toString();
    if (estimateRaw == null || estimateRaw.isEmpty) return null;

    final matches =
        RegExp(r'(\d+(?:\.\d+)?)')
            .allMatches(estimateRaw)
            .map((m) => double.parse(m.group(1)!))
            .toList();

    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    final total = matches.reduce((a, b) => a + b);
    return total / matches.length;
  }

  static int _durationSecondsToMinutes(dynamic value) {
    final seconds = _toDouble(value);
    if (seconds == null) return 0;
    return (seconds / 60).ceil();
  }

  static int _resolveCapacity(Map<String, dynamic> price) {
    final capacity = price['capacity'];
    if (capacity is int && capacity > 0) {
      return capacity;
    }

    final name =
        (price['display_name'] ?? price['localized_display_name'] ?? '')
            .toString()
            .toLowerCase();

    if (name.contains('xl') || name.contains('suv')) return 6;
    if (name.contains('pool') || name.contains('share')) return 2;
    if (name.contains('moto') || name.contains('bike')) return 1;
    return 4;
  }

  static CabType _inferCategory(String displayName) {
    final lower = displayName.toLowerCase();
    if (lower.contains('pool') || lower.contains('share')) {
      return CabType.pool;
    }
    if (lower.contains('auto')) {
      return CabType.auto;
    }
    if (lower.contains('moto') ||
        lower.contains('bike') ||
        lower.contains('scooter')) {
      return CabType.bike;
    }
    return CabType.cab;
  }

  static String? _buildDeepLink(
    String? productId,
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    if (productId == null) return null;

    final buffer = StringBuffer('uber://?action=setPickup');
    buffer
      ..write('&pickup[latitude]=$fromLat')
      ..write('&pickup[longitude]=$fromLng')
      ..write('&dropoff[latitude]=$toLat')
      ..write('&dropoff[longitude]=$toLng')
      ..write('&product_id=$productId');

    return buffer.toString();
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }
}

class UberServiceException implements Exception {
  UberServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
