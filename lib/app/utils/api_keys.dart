import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  const ApiKeys._();

  // Returns the environment value for the given key or an empty string when
  // dotenv has not been initialized yet.
  static String _read(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env[key] ?? '';
  }

  // Google APIs
  static String get googlePlacesApiKey => _read('GOOGLE_PLACES_API_KEY');

  static String get googleMapsApiKey => _read('GOOGLE_MAPS_API_KEY');

  // Uber API
  static String get uberClientId => _read('UBER_CLIENT_ID');

  static String get uberServerToken => _read('UBER_SERVER_TOKEN');

  static String get uberClientSecret => _read('UBER_CLIENT_SECRET');

  static String get uberRedirectUri => _read('UBER_REDIRECT_URI');

  static List<String> get uberDriverScopes {
    final raw = _read('UBER_DRIVER_SCOPES');
    if (raw.trim().isEmpty) {
      return const ['partner.accounts', 'partner.trips', 'partner.payments'];
    }

    final scopes =
        raw.split(RegExp(r'\s+')).where((scope) => scope.isNotEmpty).toList();

    return scopes.isEmpty
        ? const ['partner.accounts', 'partner.trips', 'partner.payments']
        : List.unmodifiable(scopes);
  }

  static bool get useUberSandbox {
    final raw = _read('UBER_USE_SANDBOX');
    final normalized = raw.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'sandbox';
  }

  // Ola API
  static String get olaApiKey => dotenv.env['OLA_API_KEY'] ?? '';

  // Rapido API (if available)
  static String get rapidoApiKey => dotenv.env['RAPIDO_API_KEY'] ?? '';

  // Validation
  static bool get hasGooglePlacesKey => googlePlacesApiKey.isNotEmpty;

  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;

  static bool get hasGoogleKeys => hasGooglePlacesKey && hasGoogleMapsKey;

  static bool get hasUberKeys =>
      uberClientId.isNotEmpty && uberServerToken.isNotEmpty;

  static bool get hasUberDriverOAuthConfig =>
      uberClientId.isNotEmpty &&
      uberClientSecret.isNotEmpty &&
      uberRedirectUri.isNotEmpty;

  static bool get hasOlaKey => olaApiKey.isNotEmpty;

  static bool get hasRapidoKey => rapidoApiKey.isNotEmpty;

  // Check if we have minimum required keys for basic functionality
  static bool get hasMinimumKeys =>
      hasGooglePlacesKey; // Places key required for core location search
}
