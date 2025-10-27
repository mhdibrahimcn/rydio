import 'dart:async';
import 'dart:developer' show log;
import 'package:url_launcher/url_launcher.dart';
import '../models/uber_auth_tokens.dart';
import '../utils/api_keys.dart';
import 'uber_token_repository.dart';

/// Handles the complete Uber OAuth 2.0 Authorization Code flow.
///
/// OAuth Flow Steps (as per Uber documentation):
/// 1. Generate authorization URL with required scopes
/// 2. User authenticates and grants permissions via Uber's login page
/// 3. Uber redirects back to app with authorization code
/// 4. Exchange authorization code for access token
/// 5. Use access token to make API requests
class UberOAuthHandler {
  UberOAuthHandler._();

  static final _instance = UberOAuthHandler._();
  static UberOAuthHandler get instance => _instance;

  final StreamController<UberAuthTokens> _tokenController =
      StreamController<UberAuthTokens>.broadcast();

  Stream<UberAuthTokens> get onTokenReceived => _tokenController.stream;

  /// Step 1 & 2: Launch the Uber authorization page in the browser
  /// This starts the OAuth flow by opening Uber's login page where the user
  /// can authenticate and grant permissions to the app.
  Future<void> startAuthorizationFlow({List<String>? scopes}) async {
    try {
      final authUrl = UberTokenRepository.getAuthorizationUrl(scopes: scopes);
      final uri = Uri.parse(authUrl);

      log(
        'Starting OAuth flow: $authUrl',
        name: 'UberOAuthHandler.startAuthorizationFlow',
      );

      final attemptedModes = <LaunchMode>[
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
        LaunchMode.inAppWebView,
      ];

      Object? lastError;
      for (final mode in attemptedModes) {
        try {
          final launched = await launchUrl(uri, mode: mode);
          if (launched) {
            log(
              'Authorization URL launched successfully using $mode',
              name: 'UberOAuthHandler.startAuthorizationFlow',
            );
            return;
          }
          lastError ??= 'LaunchMode $mode returned false';
        } catch (error) {
          lastError = error;
          log(
            'Launch attempt with $mode failed: $error',
            name: 'UberOAuthHandler.startAuthorizationFlow',
          );
        }
      }

      throw UberOAuthException(
        'Cannot launch authorization URL. Please check your URL launcher configuration.',
        lastError,
      );
    } catch (error) {
      log(
        'Failed to start authorization flow: $error',
        name: 'UberOAuthHandler.startAuthorizationFlow',
      );
      if (error is UberOAuthException) rethrow;
      throw UberOAuthException('Failed to start authorization flow', error);
    }
  }

  /// Step 3 & 4: Handle the OAuth callback with authorization code
  /// This method should be called when the app receives the redirect
  /// from Uber with the authorization code.
  ///
  /// Expected redirect format: rydio://oauth/uber/?code=<AUTHORIZATION_CODE>
  Future<UberAuthTokens> handleAuthorizationCallback(Uri callbackUri) async {
    try {
      log(
        'Handling authorization callback: ${callbackUri.toString()}',
        name: 'UberOAuthHandler.handleAuthorizationCallback',
      );

      // Validate the callback URI
      final expectedScheme = ApiKeys.uberRedirectScheme;
      if (callbackUri.scheme != expectedScheme) {
        throw UberOAuthException(
          'Invalid redirect URI scheme. Expected: $expectedScheme, Got: ${callbackUri.scheme}',
        );
      }

      // Extract the authorization code
      final authCode = callbackUri.queryParameters['code'];
      if (authCode == null || authCode.isEmpty) {
        // Check for error in callback
        final error = callbackUri.queryParameters['error'];
        final errorDescription =
            callbackUri.queryParameters['error_description'];

        if (error != null) {
          throw UberOAuthException(
            'Authorization failed: $error${errorDescription != null ? ' - $errorDescription' : ''}',
          );
        }

        throw UberOAuthException(
          'Authorization code not found in callback URI.',
        );
      }

      log(
        'Authorization code received, exchanging for access token',
        name: 'UberOAuthHandler.handleAuthorizationCallback',
      );

      // Step 4: Exchange authorization code for access token
      final tokens = await UberTokenRepository.exchangeAuthorizationCode(
        authCode,
      );

      log(
        'Successfully obtained access token',
        name: 'UberOAuthHandler.handleAuthorizationCallback',
      );

      _tokenController.add(tokens);
      return tokens;
    } catch (error) {
      log(
        'Failed to handle authorization callback: $error',
        name: 'UberOAuthHandler.handleAuthorizationCallback',
      );
      if (error is UberOAuthException) rethrow;
      throw UberOAuthException(
        'Failed to handle authorization callback',
        error,
      );
    }
  }

  /// Parse a deep link URI and handle it if it's an Uber OAuth callback
  /// Returns true if the URI was handled, false otherwise
  Future<bool> handleDeepLink(String uriString) async {
    try {
      final uri = Uri.parse(uriString);

      // Check if this is an Uber OAuth callback
      final expectedScheme = ApiKeys.uberRedirectScheme;
      if (uri.scheme != expectedScheme ||
          uri.host != 'oauth' ||
          uri.pathSegments.firstOrNull != 'uber') {
        return false; // Not an Uber OAuth callback
      }

      await handleAuthorizationCallback(uri);
      return true;
    } catch (error) {
      log(
        'Error handling deep link: $error',
        name: 'UberOAuthHandler.handleDeepLink',
      );
      return false;
    }
  }

  /// Complete authorization flow: start and wait for callback
  /// This is a convenience method that combines steps 1-4
  Future<UberAuthTokens> authorize({
    List<String>? scopes,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = Completer<UberAuthTokens>();

    StreamSubscription<UberAuthTokens>? subscription;
    Timer? timeoutTimer;

    try {
      // Listen for token
      subscription = onTokenReceived.listen((tokens) {
        if (!completer.isCompleted) {
          completer.complete(tokens);
        }
      });

      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            UberOAuthException(
              'Authorization flow timed out after ${timeout.inSeconds} seconds',
            ),
          );
        }
      });

      // Start the flow
      await startAuthorizationFlow(scopes: scopes);

      // Wait for completion
      return await completer.future;
    } finally {
      subscription?.cancel();
      timeoutTimer?.cancel();
    }
  }

  /// Check if the app is properly configured for OAuth
  bool get isConfigured => ApiKeys.hasUberOAuthConfig;

  /// Get configuration status message
  String get configurationStatus {
    if (isConfigured) {
      return 'Uber OAuth is properly configured';
    }

    final missing = <String>[];
    if (ApiKeys.uberClientId.isEmpty) missing.add('UBER_CLIENT_ID');
    if (ApiKeys.uberClientSecret.isEmpty) missing.add('UBER_CLIENT_SECRET');
    if (ApiKeys.uberRedirectUri.isEmpty) missing.add('UBER_REDIRECT_URI');

    return 'Missing configuration: ${missing.join(', ')}';
  }

  void dispose() {
    _tokenController.close();
  }
}

class UberOAuthException implements Exception {
  UberOAuthException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}
