# API Integration Guide for Rydio Cab Fare Comparison App

This guide provides step-by-step instructions for obtaining API keys and integrating with real cab service APIs.

## Overview

The app currently uses mock data for demonstration purposes. To integrate with real APIs, you'll need to obtain API keys from the respective services and configure them in your `.env` file.

## Required API Keys

### 1. Google APIs (Required for Location Services)

#### Google Places API

- **Purpose**: Location autocomplete and place details
- **Cost**: Pay-per-use (first $200/month free)
- **Steps**:
  1. Go to [Google Cloud Console](https://console.cloud.google.com/)
  2. Create a new project or select existing one
  3. Enable the "Places API" and "Maps JavaScript API"
  4. Go to "Credentials" → "Create Credentials" → "API Key"
  5. Restrict the key to your app's bundle ID for security
  6. Copy the API key to your `.env` file as `GOOGLE_PLACES_API_KEY`

#### Google Maps API

- **Purpose**: Static map previews
- **Cost**: Pay-per-use (first $200/month free)
- **Steps**:
  1. In the same Google Cloud project, enable "Maps Static API"
  2. Use the same API key or create a separate one
  3. Copy to `.env` as `GOOGLE_MAPS_API_KEY`

### 2. Uber API (Optional)

#### Uber Rides API

- **Purpose**: Real-time fare estimates from Uber
- **Cost**: Free for development
- **Steps**:
  1. Go to [Uber Developer Portal](https://developer.uber.com/)
  2. Sign up for a developer account
  3. Create a new app in the dashboard
  4. Get your "Client ID" and (legacy) "Server Token"
  5. Add to `.env`:
     ```
     UBER_CLIENT_ID=your_client_id_here
     UBER_SERVER_TOKEN=your_server_token_here
     ```

#### API Endpoints Used:

- `GET /v1.2/estimates/price` - Get fare estimates
- `GET /v1.2/estimates/time` - Get ETA estimates
- Set `UBER_USE_SANDBOX=true` in `.env` to target Uber's sandbox (`sandbox-api.uber.com` / `sandbox-login.uber.com`) while developing and revert/remove it for production.

#### Uber Drivers API (Limited Access)

- **Purpose**: Access driver profile, trips, and payments via OAuth
- **Access**: Request access on the [Drivers Product Page](https://developer.uber.com/docs/)
- **Steps**:
  1.  Register or select your Uber app in the developer dashboard
  2.  Navigate to the **Auth** tab and configure an OAuth redirect URI
  3.  Note the `Client ID` and generate a `Client Secret`
  4.  Select the scopes your integration needs (e.g. `partner.accounts`, `partner.trips`, `partner.payments`)
  5.  Add to `.env`:
      ```
      UBER_CLIENT_ID=your_client_id_here
      UBER_CLIENT_SECRET=your_client_secret_here
      UBER_REDIRECT_URI=your_registered_redirect_uri_here
      UBER_DRIVER_SCOPES=partner.accounts partner.trips partner.payments
      ```
  6.  Follow the OAuth Authorization Code flow to obtain access and refresh tokens

> **Note**: Uber is deprecating server tokens in favor of scoped access tokens. Use the Drivers API credentials whenever possible.

### 3. Ola API (Optional)

#### Ola Cabs API

- **Purpose**: Real-time fare estimates from Ola
- **Cost**: Contact Ola for pricing
- **Steps**:
  1. Visit [Ola Developer Portal](https://developers.olacabs.com/)
  2. Register as a developer
  3. Create an application
  4. Get your API key
  5. Add to `.env`:
     ```
     OLA_API_KEY=your_api_key_here
     ```

#### API Endpoints Used:

- `POST /v1/bookings/create` - Create booking and get estimates
- `GET /v1/bookings/{booking_id}` - Get booking details

### 4. Rapido API (Optional)

#### Rapido API

- **Purpose**: Real-time fare estimates from Rapido
- **Status**: Unofficial API (use with caution)
- **Note**: Rapido doesn't have an official public API
- **Alternative**: Use web scraping or reverse engineering (not recommended for production)

If you find an official API, add to `.env`:

```
RAPIDO_API_KEY=your_api_key_here
```

## Configuration

### Environment Variables

Create a `.env` file in your project root:

```env
# Google APIs (Required)
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Uber API (Optional)
UBER_CLIENT_ID=your_uber_client_id_here
UBER_SERVER_TOKEN=your_uber_server_token_here
UBER_CLIENT_SECRET=your_uber_client_secret_here
UBER_REDIRECT_URI=your_uber_redirect_uri_here
UBER_DRIVER_SCOPES=partner.accounts partner.trips partner.payments
UBER_USE_SANDBOX=true

# Ola API (Optional)
OLA_API_KEY=your_ola_api_key_here

# Rapido API (Optional)
RAPIDO_API_KEY=your_rapido_api_key_here

# Development Settings
DEBUG_MODE=true
MOCK_API_RESPONSES=false
```

### Switching from Mock to Real APIs

1. **Set `MOCK_API_RESPONSES=false`** in your `.env` file
2. **Add your API keys** to the `.env` file
3. **Restart the app** to load new environment variables
4. **Test with real locations** to verify API integration

## API Rate Limits and Costs

### Google APIs

- **Places API**: 1,000 requests/day free, then $0.017 per request
- **Maps Static API**: 25,000 requests/month free, then $0.002 per request

### Uber API

- **Development**: Free with rate limits
- **Production**: Contact Uber for commercial pricing

### Ola API

- **Contact Ola** for pricing and rate limits

## Security Considerations

### API Key Security

1. **Never commit API keys** to version control
2. **Use environment variables** (`.env` file)
3. **Restrict API keys** to specific domains/apps
4. **Rotate keys regularly**
5. **Monitor usage** for unusual activity

### Production Deployment

1. **Use server-side proxy** for sensitive API calls
2. **Implement proper authentication**
3. **Add request validation**
4. **Use HTTPS** for all API calls
5. **Implement caching** to reduce API calls

## Testing

### Mock vs Real Data

- **Mock data**: Instant responses, no API costs
- **Real data**: Actual fares, API costs, network dependency

### Testing Checklist

- [ ] Location search works with Google Places API
- [ ] Map preview displays correctly
- [ ] Fare estimates are realistic
- [ ] Deep links open respective apps
- [ ] Error handling works for API failures
- [ ] Rate limiting is handled gracefully

## Troubleshooting

### Common Issues

1. **API Key Not Working**

   - Check if the key is correctly copied
   - Verify API is enabled in the console
   - Check if restrictions are too strict

2. **CORS Errors**

   - Use server-side proxy for web deployment
   - Configure CORS headers on your server

3. **Rate Limit Exceeded**

   - Implement exponential backoff
   - Add request caching
   - Monitor usage in API console

4. **Invalid Location Data**
   - Validate coordinates before API calls
   - Handle edge cases (invalid addresses)
   - Provide fallback to mock data

### Debug Mode

Set `DEBUG_MODE=true` in `.env` to enable:

- Detailed error logging
- API request/response logging
- Performance metrics

## Production Considerations

### Performance

- **Cache API responses** for 5-10 minutes
- **Implement request debouncing**
- **Use background refresh** for fare updates
- **Optimize image loading** for maps

### Scalability

- **Use CDN** for static assets
- **Implement proper error handling**
- **Add monitoring and analytics**
- **Plan for API rate limits**

### Legal Compliance

- **Review API terms of service**
- **Implement proper attribution**
- **Follow platform guidelines**
- **Consider data privacy regulations**

## Support

### Google APIs

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Google Cloud Support](https://cloud.google.com/support)

### Uber API

- [Uber Developer Documentation](https://developer.uber.com/docs)
- [Uber Developer Support](https://developer.uber.com/support)

### Ola API

- [Ola Developer Documentation](https://developers.olacabs.com/docs)
- Contact Ola directly for support

## Conclusion

This app is designed to work with mock data out of the box, but can be easily configured to use real APIs for production use. Start with Google APIs for location services, then gradually add cab service APIs as needed.

Remember to always test thoroughly and monitor API usage to avoid unexpected costs.
