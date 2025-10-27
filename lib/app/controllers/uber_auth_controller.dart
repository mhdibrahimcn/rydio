import 'dart:async';
import 'dart:developer' show log;
import 'package:get/get.dart';
import '../models/uber_auth_tokens.dart';
import '../services/uber_oauth_handler.dart';
import '../services/uber_token_repository.dart';

/// Controller for managing Uber OAuth authentication state
class UberAuthController extends GetxController {
  // Observable state
  final _isAuthenticated = false.obs;
  final _isAuthenticating = false.obs;
  final _accessToken = Rxn<String>();
  final _tokens = Rxn<UberAuthTokens>();
  final _errorMessage = Rxn<String>();

  StreamSubscription<UberAuthTokens>? _tokenSubscription;

  // Getters
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isAuthenticating => _isAuthenticating.value;
  Rx<bool> get isAuthorizing => _isAuthenticating; // Alias for compatibility
  String? get accessToken => _accessToken.value;
  UberAuthTokens? get tokens => _tokens.value;
  Rxn<String> get errorMessage => _errorMessage; // Return Rxn for .value access
  bool get isConfigured => UberOAuthHandler.instance.isConfigured;
  String get configurationStatus =>
      UberOAuthHandler.instance.configurationStatus;

  @override
  void onInit() {
    super.onInit();

    // Listen for tokens from OAuth flow
    _tokenSubscription = UberOAuthHandler.instance.onTokenReceived.listen(
      _handleTokenReceived,
      onError: (error) {
        log('Token stream error: $error', name: 'UberAuthController');
        _errorMessage.value = error.toString();
      },
    );

    // Check if we have cached tokens
    _checkCachedTokens();
  }

  @override
  void onClose() {
    _tokenSubscription?.cancel();
    super.onClose();
  }

  /// Check if we have valid cached tokens
  Future<void> _checkCachedTokens() async {
    try {
      final token = await UberTokenRepository.getAccessToken();
      if (token.isNotEmpty) {
        _accessToken.value = token;
        _isAuthenticated.value = true;
        log('Found valid cached token', name: 'UberAuthController');
      }
    } catch (e) {
      log('No valid cached token: $e', name: 'UberAuthController');
      // No valid token, user needs to authenticate
    }
  }

  /// Start the OAuth authorization flow
  Future<void> startAuthorization({List<String>? scopes}) async {
    if (_isAuthenticating.value) {
      log('Authorization already in progress', name: 'UberAuthController');
      return;
    }

    _isAuthenticating.value = true;
    _errorMessage.value = null;

    try {
      log('Starting authorization flow', name: 'UberAuthController');

      await UberOAuthHandler.instance.startAuthorizationFlow(scopes: scopes);

      // The actual token will come through the stream when redirect happens
      log('Authorization URL launched', name: 'UberAuthController');
    } catch (e) {
      log('Authorization failed: $e', name: 'UberAuthController');
      _errorMessage.value = e.toString();
      _isAuthenticating.value = false;
    }
  }

  /// Handle deep link (OAuth callback)
  Future<bool> handleDeepLink(String uriString) async {
    try {
      log('Handling deep link: $uriString', name: 'UberAuthController');

      final handled = await UberOAuthHandler.instance.handleDeepLink(uriString);

      if (handled) {
        log('Deep link handled successfully', name: 'UberAuthController');
      }

      return handled;
    } catch (e) {
      log('Error handling deep link: $e', name: 'UberAuthController');
      _errorMessage.value = e.toString();
      _isAuthenticating.value = false;
      return false;
    }
  }

  /// Handle received tokens
  void _handleTokenReceived(UberAuthTokens tokens) {
    log('Received tokens', name: 'UberAuthController');

    _tokens.value = tokens;
    _accessToken.value = tokens.accessToken;
    _isAuthenticated.value = true;
    _isAuthenticating.value = false;
    _errorMessage.value = null;

    log('Authentication successful', name: 'UberAuthController');
  }

  /// Get a valid access token (from cache or new)
  Future<String> getAccessToken() async {
    try {
      final token = await UberTokenRepository.getAccessToken();
      _accessToken.value = token;
      _isAuthenticated.value = true;
      return token;
    } catch (e) {
      log('Failed to get access token: $e', name: 'UberAuthController');
      _errorMessage.value = e.toString();
      _isAuthenticated.value = false;
      rethrow;
    }
  }

  /// Use Client Credentials flow (no user auth required)
  Future<void> authenticateWithClientCredentials({List<String>? scopes}) async {
    _isAuthenticating.value = true;
    _errorMessage.value = null;

    try {
      log('Authenticating with client credentials', name: 'UberAuthController');

      final tokens = await UberTokenRepository.getClientCredentialsToken(
        scopes: scopes,
      );

      _handleTokenReceived(tokens);
    } catch (e) {
      log('Client credentials auth failed: $e', name: 'UberAuthController');
      _errorMessage.value = e.toString();
      _isAuthenticating.value = false;
      rethrow;
    }
  }

  /// Refresh the current token
  Future<void> refreshToken() async {
    final currentTokens = _tokens.value;
    if (currentTokens?.refreshToken == null) {
      log('No refresh token available', name: 'UberAuthController');
      return;
    }

    try {
      log('Refreshing token', name: 'UberAuthController');

      final tokens = await UberTokenRepository.refreshAccessToken(
        currentTokens!.refreshToken!,
      );

      _handleTokenReceived(tokens);
    } catch (e) {
      log('Token refresh failed: $e', name: 'UberAuthController');
      _errorMessage.value = e.toString();
      _isAuthenticated.value = false;
      rethrow;
    }
  }

  /// Sign out and clear tokens
  void signOut() {
    log('Signing out', name: 'UberAuthController');

    UberTokenRepository.clearCache();

    _tokens.value = null;
    _accessToken.value = null;
    _isAuthenticated.value = false;
    _isAuthenticating.value = false;
    _errorMessage.value = null;

    log('Signed out successfully', name: 'UberAuthController');
  }

  /// Alias for signOut (for compatibility)
  void clearSession() => signOut();

  /// Ensure we have a valid access token, get one if needed
  Future<String> ensureAccessToken() async {
    // If we have a valid cached token, return it
    if (_isAuthenticated.value && _accessToken.value != null) {
      try {
        // Verify it's still valid
        final token = await UberTokenRepository.getAccessToken();
        return token;
      } catch (e) {
        log(
          'Cached token invalid, need new one: $e',
          name: 'UberAuthController',
        );
      }
    }

    // Try to get a new token using client credentials
    try {
      log(
        'Getting access token via client credentials',
        name: 'UberAuthController',
      );
      await authenticateWithClientCredentials();
      return _accessToken.value!;
    } catch (e) {
      log('Failed to ensure access token: $e', name: 'UberAuthController');
      throw Exception('Failed to get Uber access token: $e');
    }
  }

  /// Clear any error messages
  void clearError() {
    _errorMessage.value = null;
  }
}
