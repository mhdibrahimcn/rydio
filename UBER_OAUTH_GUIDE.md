# Uber OAuth 2.0 Integration Guide

## Overview

This guide explains how to use the Uber OAuth 2.0 implementation in the Rydio app. The implementation follows Uber's official OAuth documentation and supports both **Authorization Code** and **Client Credentials** grant types.

## OAuth Grant Types

### 1. Authorization Code Flow
Use this to access individual user data or perform actions on their behalf (e.g., requesting rides, accessing user profile).

**Scopes**: User-specific permissions like `profile`, `rides.read`, `rides.request`

### 2. Client Credentials Flow
Use this for application-level access without user authorization (e.g., accessing public products, fare estimates).

**Scopes**: Application-level permissions like `partner.accounts`, `partner.trips`

---

## Configuration

### Step 1: Set up Environment Variables

Create a `.env` file in the project root with the following:

```env
# Uber OAuth Configuration
UBER_CLIENT_ID=your_client_id_here
UBER_CLIENT_SECRET=your_client_secret_here
UBER_REDIRECT_URI=rydio://oauth/uber

# Uber Scopes (space-delimited)
UBER_SCOPES=profile rides.read rides.request rides.estimate

# Use Sandbox for Testing
UBER_USE_SANDBOX=true
```

### Step 2: Configure Android Deep Links

The `AndroidManifest.xml` is already configured to handle the OAuth redirect:

```xml
<intent-filter android:label="uber_oauth">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="rydio" android:host="oauth" android:pathPrefix="/uber" />
</intent-filter>
```

---

## Authorization Code Flow (5 Steps)

### Step 1: Generate Authorization URL

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// Generate the authorization URL with required scopes
final authUrl = UberTokenRepository.getAuthorizationUrl(
  scopes: ['profile', 'rides.read', 'rides.request'],
);

print('Authorization URL: $authUrl');
// Output: https://sandbox-login.uber.com/oauth/v2/authorize?client_id=...&redirect_uri=...&scope=...&response_type=code
```

### Step 2: Launch Authorization Page

```dart
import 'package:rydio/app/services/uber_oauth_handler.dart';

// Start the OAuth flow - opens Uber's login page in browser
await UberOAuthHandler.instance.startAuthorizationFlow(
  scopes: ['profile', 'rides.read', 'rides.request'],
);
```

The user will be redirected to Uber's authentication page where they can:
- Sign in with their Uber credentials
- Review the requested permissions
- Grant or deny access to your app

### Step 3: Handle OAuth Callback

After the user authorizes, Uber redirects to: `rydio://oauth/uber/?code=<AUTHORIZATION_CODE>`

The app automatically handles this via deep linking. Set up a listener in your main app:

```dart
import 'package:rydio/app/services/uber_oauth_handler.dart';

// Listen for incoming tokens
UberOAuthHandler.instance.onTokenReceived.listen((tokens) {
  print('Access Token: ${tokens.accessToken}');
  print('Expires In: ${tokens.expiresIn} seconds');
  print('Refresh Token: ${tokens.refreshToken}');
  print('Scopes: ${tokens.scope.join(', ')}');
  
  // Save tokens for later use
  // e.g., store in secure storage
});
```

### Step 4: Exchange Authorization Code (Automatic)

When your app receives the deep link, handle it:

```dart
// In your app's deep link handler
Future<void> handleIncomingLink(Uri uri) async {
  final handled = await UberOAuthHandler.instance.handleDeepLink(
    uri.toString(),
  );
  
  if (handled) {
    print('OAuth callback handled successfully');
  }
}
```

Or manually exchange the code:

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// If you extracted the code manually from the callback URI
final tokens = await UberTokenRepository.exchangeAuthorizationCode(
  authorizationCode,
);

print('Access Token: ${tokens.accessToken}');
```

### Step 5: Use Access Token

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// Get a valid access token (from cache or refresh if needed)
final accessToken = await UberTokenRepository.getAccessToken();

// Use the token in API requests
final response = await http.get(
  Uri.parse('https://sandbox-api.uber.com/v1.2/products?latitude=37.7759792&longitude=-122.41823'),
  headers: {
    'Authorization': 'Bearer $accessToken',
    'Accept': 'application/json',
  },
);
```

---

## Complete Authorization Flow (One Method)

Use the convenience method to handle the entire flow:

```dart
import 'package:rydio/app/services/uber_oauth_handler.dart';

try {
  // This will:
  // 1. Generate auth URL
  // 2. Launch browser
  // 3. Wait for callback
  // 4. Exchange code for token
  // 5. Return the token
  final tokens = await UberOAuthHandler.instance.authorize(
    scopes: ['profile', 'rides.read', 'rides.request'],
    timeout: Duration(minutes: 5),
  );
  
  print('Successfully authorized!');
  print('Access Token: ${tokens.accessToken}');
} catch (e) {
  print('Authorization failed: $e');
}
```

---

## Client Credentials Flow

For app-level access (no user authentication needed):

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

try {
  // Get client credentials token
  final tokens = await UberTokenRepository.getClientCredentialsToken(
    scopes: ['partner.accounts', 'partner.trips'],
  );
  
  print('Client Token: ${tokens.accessToken}');
  print('Expires In: ${tokens.expiresIn} seconds');
  
  // Use the token for API requests
  final accessToken = tokens.accessToken;
  
} catch (e) {
  print('Failed to get client credentials: $e');
}
```

---

## Token Management

### Auto-Refresh Tokens

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// getAccessToken automatically handles token refresh
final accessToken = await UberTokenRepository.getAccessToken();
// Returns cached token if valid, refreshes if expired, or fetches new token
```

### Manual Token Refresh

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// If you have a refresh token
final refreshedTokens = await UberTokenRepository.refreshAccessToken(
  oldTokens.refreshToken!,
);

print('New Access Token: ${refreshedTokens.accessToken}');
```

### Clear Token Cache

```dart
import 'package:rydio/app/services/uber_token_repository.dart';

// Clear cached tokens (e.g., on logout)
UberTokenRepository.clearCache();
```

---

## Error Handling

```dart
import 'package:rydio/app/services/uber_token_repository.dart';
import 'package:rydio/app/services/uber_oauth_handler.dart';

try {
  final tokens = await UberOAuthHandler.instance.authorize();
  print('Success: ${tokens.accessToken}');
} on UberOAuthException catch (e) {
  print('OAuth Error: ${e.message}');
  if (e.cause != null) {
    print('Cause: ${e.cause}');
  }
} on UberTokenException catch (e) {
  print('Token Error: ${e.message}');
  if (e.cause != null) {
    print('Cause: ${e.cause}');
  }
} catch (e) {
  print('Unexpected Error: $e');
}
```

---

## Configuration Check

```dart
import 'package:rydio/app/services/uber_oauth_handler.dart';

// Check if OAuth is properly configured
if (UberOAuthHandler.instance.isConfigured) {
  print('OAuth is ready!');
} else {
  print(UberOAuthHandler.instance.configurationStatus);
  // Output: Missing configuration: UBER_CLIENT_ID, UBER_CLIENT_SECRET
}
```

---

## Testing with Sandbox

For development, use Uber's sandbox environment:

1. Set `UBER_USE_SANDBOX=true` in `.env`
2. Use sandbox credentials from Uber Developer Dashboard
3. Sandbox URLs will be automatically used:
   - Auth: `https://sandbox-login.uber.com/oauth/v2`
   - API: `https://sandbox-api.uber.com/v1.2`

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:rydio/app/services/uber_oauth_handler.dart';
import 'package:rydio/app/services/uber_token_repository.dart';

class UberAuthPage extends StatefulWidget {
  @override
  _UberAuthPageState createState() => _UberAuthPageState();
}

class _UberAuthPageState extends State<UberAuthPage> {
  String? _accessToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Listen for tokens
    UberOAuthHandler.instance.onTokenReceived.listen((tokens) {
      setState(() {
        _accessToken = tokens.accessToken;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully authorized with Uber!')),
      );
    });
  }

  Future<void> _startAuthorization() async {
    setState(() => _isLoading = true);
    
    try {
      await UberOAuthHandler.instance.startAuthorizationFlow(
        scopes: ['profile', 'rides.read'],
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authorization failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Uber Authorization')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_accessToken != null) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text('Authorized Successfully!'),
              SizedBox(height: 8),
              Text('Token: ${_accessToken!.substring(0, 20)}...'),
            ] else ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _startAuthorization,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Authorize with Uber'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## API Reference

### UberTokenRepository

- `getAuthorizationUrl({scopes})` - Generate OAuth authorization URL
- `exchangeAuthorizationCode(code)` - Exchange code for access token
- `refreshAccessToken(refreshToken)` - Refresh an expired token
- `getClientCredentialsToken({scopes})` - Get app-level token
- `getAccessToken()` - Get valid token (auto-refresh)
- `clearCache()` - Clear cached tokens

### UberOAuthHandler

- `startAuthorizationFlow({scopes})` - Launch OAuth in browser
- `handleAuthorizationCallback(uri)` - Process OAuth redirect
- `handleDeepLink(uriString)` - Handle incoming deep link
- `authorize({scopes, timeout})` - Complete OAuth flow
- `onTokenReceived` - Stream of received tokens
- `isConfigured` - Check OAuth configuration
- `configurationStatus` - Get configuration details

---

## Troubleshooting

### Issue: "OAuth redirect not working"
- Verify `UBER_REDIRECT_URI` matches your Uber Dashboard settings
- Check AndroidManifest.xml deep link configuration
- Ensure app is properly handling incoming links

### Issue: "Invalid client credentials"
- Verify `UBER_CLIENT_ID` and `UBER_CLIENT_SECRET` are correct
- Check if using sandbox credentials with `UBER_USE_SANDBOX=true`

### Issue: "Scope not authorized"
- Verify requested scopes match those enabled in Uber Dashboard
- Check if scopes are appropriate for the grant type

---

## Additional Resources

- [Uber API Documentation](https://developer.uber.com/docs)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Uber Scopes Reference](https://developer.uber.com/docs/riders/references/api/v2/scopes)
