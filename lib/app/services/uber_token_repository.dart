import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import '../models/uber_auth_tokens.dart';
import '../utils/api_keys.dart';
import '../utils/constants.dart';

/// Repository for managing Uber OAuth 2.0 authentication tokens.
///
/// Supports two OAuth grant types:
/// 1. Authorization Code - For accessing user data or acting on their behalf
/// 2. Client Credentials - For application-level API access
class UberTokenRepository {
  const UberTokenRepository._();

  static UberAuthTokens? _cachedTokens;

  static String get _authBaseUrl =>
      ApiKeys.useUberSandbox
          ? AppConstants.uberSandboxAuthBaseUrl
          : AppConstants.uberAuthBaseUrl;

  /// Step 1: Generate the authorization URL for user to grant permissions
  /// This is the first step in the Authorization Code flow
  static String getAuthorizationUrl({List<String>? scopes}) {
    if (!ApiKeys.hasUberOAuthConfig) {
      throw UberTokenException(
        'Uber OAuth configuration is incomplete. Set UBER_CLIENT_ID, UBER_CLIENT_SECRET, and UBER_REDIRECT_URI.',
      );
    }

    final scopeList = scopes ?? ApiKeys.uberScopes;
    final scopeString = scopeList.join(' ');

    final uri = Uri.parse('$_authBaseUrl/authorize').replace(
      queryParameters: {
        'client_id': ApiKeys.uberClientId,
        'redirect_uri': ApiKeys.uberRedirectUri,
        'scope': scopeString,
        'response_type': 'code',
      },
    );

    log(
      'Generated authorization URL with scopes: $scopeString',
      name: 'UberTokenRepository.getAuthorizationUrl',
    );

    return uri.toString();
  }

  /// Step 4: Exchange authorization code for access token
  /// This completes the Authorization Code flow
  static Future<UberAuthTokens> exchangeAuthorizationCode(
    String authorizationCode,
  ) async {
    if (!ApiKeys.hasUberOAuthConfig) {
      throw UberTokenException(
        'Uber OAuth configuration is incomplete. Set UBER_CLIENT_ID, UBER_CLIENT_SECRET, and UBER_REDIRECT_URI.',
      );
    }

    if (authorizationCode.isEmpty) {
      throw UberTokenException('Authorization code cannot be empty.');
    }

    final uri = Uri.parse('$_authBaseUrl/token');
    final body = {
      'client_id': ApiKeys.uberClientId,
      'client_secret': ApiKeys.uberClientSecret,
      'grant_type': 'authorization_code',
      'redirect_uri': ApiKeys.uberRedirectUri,
      'code': authorizationCode,
    };

    try {
      log(
        'Exchanging authorization code for access token',
        name: 'UberTokenRepository.exchangeAuthorizationCode',
      );

      final tokens = await _requestToken(uri, body);
      _cachedTokens = tokens;

      log(
        'Successfully obtained access token (expires in ${tokens.expiresIn}s)',
        name: 'UberTokenRepository.exchangeAuthorizationCode',
      );

      return tokens;
    } catch (error) {
      if (error is UberTokenException) rethrow;
      throw UberTokenException(
        'Failed to exchange authorization code for access token',
        error,
      );
    }
  }

  /// Refresh an expired access token using the refresh token
  static Future<UberAuthTokens> refreshAccessToken(String refreshToken) async {
    if (!ApiKeys.hasUberOAuthConfig) {
      throw UberTokenException(
        'Uber OAuth configuration is incomplete. Set UBER_CLIENT_ID and UBER_CLIENT_SECRET.',
      );
    }

    if (refreshToken.isEmpty) {
      throw UberTokenException('Refresh token cannot be empty.');
    }

    final uri = Uri.parse('$_authBaseUrl/token');
    final body = {
      'client_id': ApiKeys.uberClientId,
      'client_secret': ApiKeys.uberClientSecret,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };

    try {
      log(
        'Refreshing access token',
        name: 'UberTokenRepository.refreshAccessToken',
      );

      final tokens = await _requestToken(uri, body);
      _cachedTokens = tokens;

      log(
        'Successfully refreshed access token (expires in ${tokens.expiresIn}s)',
        name: 'UberTokenRepository.refreshAccessToken',
      );

      return tokens;
    } catch (error) {
      if (error is UberTokenException) rethrow;
      throw UberTokenException('Failed to refresh access token', error);
    }
  }

  /// Get access token using Client Credentials grant
  /// This is for application-level access without user authorization
  static Future<UberAuthTokens> getClientCredentialsToken({
    List<String>? scopes,
  }) async {
    if (ApiKeys.uberClientId.isEmpty || ApiKeys.uberClientSecret.isEmpty) {
      throw UberTokenException(
        'Uber client credentials are not configured. Set UBER_CLIENT_ID and UBER_CLIENT_SECRET.',
      );
    }

    final scopeList = scopes ?? ApiKeys.uberScopes;
    if (scopeList.isEmpty) {
      throw UberTokenException(
        'At least one Uber scope is required for client credentials.',
      );
    }

    final uri = Uri.parse('$_authBaseUrl/token');
    final body = {
      'client_id': ApiKeys.uberClientId,
      'client_secret': ApiKeys.uberClientSecret,
      'grant_type': 'client_credentials',
      'scope': scopeList.join(' '),
    };

    try {
      log(
        'Requesting client credentials token with scopes: ${body['scope']}',
        name: 'UberTokenRepository.getClientCredentialsToken',
      );

      final tokens = await _requestToken(uri, body);
      _cachedTokens = tokens;

      log(
        'Successfully obtained client credentials token (expires in ${tokens.expiresIn}s)',
        name: 'UberTokenRepository.getClientCredentialsToken',
      );

      return tokens;
    } catch (error) {
      if (error is UberTokenException) rethrow;
      throw UberTokenException(
        'Failed to obtain client credentials token',
        error,
      );
    }
  }

  /// Get a valid access token from cache or fetch a new one
  static Future<String> getAccessToken() async {
    final cached = _cachedTokens;

    // Return cached token if valid
    if (cached != null && !cached.isExpired) {
      log(
        'Reusing cached access token (expires in ${cached.timeToExpiry.inSeconds}s)',
        name: 'UberTokenRepository.getAccessToken',
      );
      return cached.accessToken;
    }

    // Try to refresh if we have a refresh token
    if (cached?.refreshToken != null && cached!.refreshToken!.isNotEmpty) {
      try {
        final refreshed = await refreshAccessToken(cached.refreshToken!);
        return refreshed.accessToken;
      } catch (error) {
        log(
          'Failed to refresh token: $error',
          name: 'UberTokenRepository.getAccessToken',
        );
        // Fall through to get new token
      }
    }

    // Default to client credentials grant
    final tokens = await getClientCredentialsToken();
    return tokens.accessToken;
  }

  /// Make a token request to Uber's OAuth endpoint
  static Future<UberAuthTokens> _requestToken(
    Uri uri,
    Map<String, String> body,
  ) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    try {
      final response = await http.post(uri, headers: headers, body: body);

      log(
        'Token request response: ${response.statusCode}',
        name: 'UberTokenRepository._requestToken',
      );

      final payload = _decodeBody(response);

      if (_isSuccess(response.statusCode)) {
        final tokens = UberAuthTokens.fromJson(payload);

        if (tokens.accessToken.isEmpty) {
          throw UberTokenException('Uber did not return an access token.');
        }

        return tokens;
      }

      throw UberTokenException(
        _extractErrorMessage(payload) ??
            'Uber token request failed (${response.statusCode}).',
      );
    } catch (error) {
      if (error is UberTokenException) rethrow;
      throw UberTokenException('Token request failed', error);
    }
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
    } catch (error) {
      throw UberTokenException(
        'Failed to parse Uber token response (status: ${response.statusCode}).',
        error,
      );
    }
  }

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static String? _extractErrorMessage(Map<String, dynamic> payload) {
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

    return null;
  }

  /// Clear the cached tokens
  static void clearCache() {
    _cachedTokens = null;
    log('Token cache cleared', name: 'UberTokenRepository.clearCache');
  }
}

class UberTokenException implements Exception {
  UberTokenException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
