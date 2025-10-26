class AppConstants {
  // App Info
  static const String appName = 'Rydio';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String uberBaseUrl = 'https://api.uber.com/v1.2';
  static const String uberAuthBaseUrl = 'https://auth.uber.com/oauth/v2';
  static const String uberSandboxBaseUrl = 'https://sandbox-api.uber.com/v1.2';
  static const String uberSandboxAuthBaseUrl =
      'https://sandbox-login.uber.com/oauth/v2';
  static const String olaBaseUrl = 'https://devapi.olacabs.com/v1';
  static const String rapidoBaseUrl = 'https://api.rapido.bike/api';
  static const String googlePlacesUrl =
      'https://maps.googleapis.com/maps/api/place';
  static const String googleMapsUrl = 'https://maps.googleapis.com/maps/api';

  // Deep Links
  static const String uberDeepLink = 'uber://';
  static const String olaDeepLink = 'oladriver://';
  static const String rapidoDeepLink = 'rapido://';

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 56.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Search Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Cache Duration
  static const Duration cacheDuration = Duration(minutes: 5);
}
