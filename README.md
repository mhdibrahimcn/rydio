# Rydio

Rydio compares real-time ride fares from mobility providers. The app now
integrates with Uber's OAuth flow so users can authenticate and fetch live
price estimates directly from Uber's APIs.

## Uber OAuth Setup

1. Create an Uber developer application and enable the sandbox environment
	while testing.
2. Configure a redirect URI that uses a custom scheme (e.g.
	`rydio://oauth/uber`). Add the same scheme and host
	to the Android and iOS platform projects so the OAuth callback returns
	to the app.
3. Add the following keys to `.env` (or your secure secrets store):

	```env
	UBER_CLIENT_ID=your_client_id
	UBER_CLIENT_SECRET=your_client_secret
	UBER_REDIRECT_URI=rydio://oauth/uber
	UBER_SCOPES=profile rides.read rides.request rides.estimate
	UBER_USE_SANDBOX=true
	```

4. Run `flutter pub get` to install dependencies (`flutter_web_auth_2` is used
	for the OAuth browser session).
5. In the app, tap **Connect Uber** and complete the login flow. Once
	authorized, you can compare live Uber fares for the selected route.

## Running the App

```bash
flutter pub get
flutter run
```
