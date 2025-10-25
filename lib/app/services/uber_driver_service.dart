import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver_payment_model.dart';
import '../models/driver_profile_model.dart';
import '../models/driver_trip_model.dart';
import '../models/uber_driver_tokens.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

class UberDriverService {
  const UberDriverService._();

  static String get _authBaseUrl =>
      ApiKeys.useUberSandbox
          ? AppConstants.uberSandboxAuthBaseUrl
          : AppConstants.uberAuthBaseUrl;

  static String get _driverBaseUrl =>
      ApiKeys.useUberSandbox
          ? AppConstants.uberSandboxDriverBaseUrl
          : AppConstants.uberDriverBaseUrl;

  static Uri buildAuthorizationUrl({String? state, List<String>? scopes}) {
    _ensureOAuthConfigured();

    final resolvedScopes = scopes ?? ApiKeys.uberDriverScopes;
    final query = <String, String>{
      'response_type': 'code',
      'client_id': ApiKeys.uberClientId,
      'redirect_uri': ApiKeys.uberRedirectUri,
      'scope': resolvedScopes.join(' '),
    };

    if (state != null && state.isNotEmpty) {
      query['state'] = state;
    }

    return Uri.parse('$_authBaseUrl/authorize').replace(queryParameters: query);
  }

  static Future<UberDriverTokens> exchangeAuthorizationCode(
    String authorizationCode,
  ) async {
    _ensureOAuthConfigured();

    final response = await _postForm(Uri.parse('$_authBaseUrl/token'), {
      'client_id': ApiKeys.uberClientId,
      'client_secret': ApiKeys.uberClientSecret,
      'grant_type': 'authorization_code',
      'redirect_uri': ApiKeys.uberRedirectUri,
      'code': authorizationCode,
    });

    return UberDriverTokens.fromJson(response);
  }

  static Future<UberDriverTokens> refreshAccessToken(
    String refreshToken,
  ) async {
    _ensureOAuthConfigured();

    final response = await _postForm(Uri.parse('$_authBaseUrl/token'), {
      'client_id': ApiKeys.uberClientId,
      'client_secret': ApiKeys.uberClientSecret,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });

    return UberDriverTokens.fromJson(response);
  }

  static Future<DriverProfileModel> fetchProfile(String accessToken) async {
    final data = await _getJson(
      Uri.parse('$_driverBaseUrl/partners/me'),
      accessToken,
    );

    return DriverProfileModel.fromJson(data);
  }

  static Future<List<DriverTripModel>> fetchTrips(
    String accessToken, {
    int limit = 10,
    int offset = 0,
  }) async {
    final data = await _getJson(
      Uri.parse('$_driverBaseUrl/partners/trips').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      ),
      accessToken,
    );

    final trips =
        (data['trips'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(DriverTripModel.fromJson)
            .toList() ??
        const <DriverTripModel>[];

    return trips;
  }

  static Future<List<DriverPaymentModel>> fetchPayments(
    String accessToken, {
    int limit = 10,
    int offset = 0,
  }) async {
    final data = await _getJson(
      Uri.parse('$_driverBaseUrl/partners/payments').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      ),
      accessToken,
    );

    final payments =
        (data['payments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(DriverPaymentModel.fromJson)
            .toList() ??
        const <DriverPaymentModel>[];

    return payments;
  }

  static Future<Map<String, dynamic>> _postForm(
    Uri uri,
    Map<String, String> body,
  ) async {
    try {
      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      final payload = _decodeBody(response);

      if (_isSuccess(response.statusCode)) {
        return payload;
      }

      throw UberDriverApiException(
        response.statusCode,
        _extractErrorMessage(payload),
      );
    } catch (error) {
      if (error is UberDriverApiException) rethrow;
      throw UberDriverApiException(0, error.toString());
    }
  }

  static Future<Map<String, dynamic>> _getJson(
    Uri uri,
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        uri,
        headers: _authorizedHeaders(accessToken),
      );
      final payload = _decodeBody(response);

      if (_isSuccess(response.statusCode)) {
        return payload;
      }

      throw UberDriverApiException(
        response.statusCode,
        _extractErrorMessage(payload),
      );
    } catch (error) {
      if (error is UberDriverApiException) rethrow;
      throw UberDriverApiException(0, error.toString());
    }
  }

  static Map<String, String> _authorizedHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': 'en_US',
    };
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return const {};
    }

    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      throw UberDriverApiException(
        response.statusCode,
        'Failed to parse Uber API response',
      );
    }
  }

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static String _extractErrorMessage(Map<String, dynamic> payload) {
    final candidates = [
      payload['error_description'],
      payload['description'],
      payload['error'],
      payload['message'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return 'Unexpected Uber API response';
  }

  static void _ensureOAuthConfigured() {
    if (!ApiKeys.hasUberDriverOAuthConfig) {
      throw UberDriverConfigurationException(
        'Uber driver OAuth credentials are missing. Please set UBER_CLIENT_ID, UBER_CLIENT_SECRET, and UBER_REDIRECT_URI.',
      );
    }
  }
}

class UberDriverApiException implements Exception {
  UberDriverApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() =>
      'UberDriverApiException(statusCode: $statusCode, message: $message)';
}

class UberDriverConfigurationException implements Exception {
  UberDriverConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
