class DriverTripModel {
  DriverTripModel({
    required this.tripId,
    this.driverId,
    this.vehicleId,
    this.status,
    this.durationSeconds,
    this.distance,
    this.fare,
    this.currencyCode,
    this.surgeMultiplier,
    this.pickupTimestamp,
    this.dropoffTimestamp,
    this.startCity,
    this.statusChanges = const [],
  });

  final String tripId;
  final String? driverId;
  final String? vehicleId;
  final String? status;
  final int? durationSeconds;
  final double? distance;
  final double? fare;
  final String? currencyCode;
  final double? surgeMultiplier;
  final DateTime? pickupTimestamp;
  final DateTime? dropoffTimestamp;
  final DriverTripCity? startCity;
  final List<DriverTripStatusChange> statusChanges;

  factory DriverTripModel.fromJson(Map<String, dynamic> json) {
    final statusChanges =
        (json['status_changes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(DriverTripStatusChange.fromJson)
            .toList() ??
        const <DriverTripStatusChange>[];

    return DriverTripModel(
      tripId: json['trip_id']?.toString() ?? '',
      driverId: json['driver_id']?.toString(),
      vehicleId: json['vehicle_id']?.toString(),
      status: json['status']?.toString(),
      durationSeconds: _tryParseInt(json['duration']),
      distance: _tryParseDouble(json['distance']),
      fare: _tryParseDouble(json['fare']),
      currencyCode: json['currency_code']?.toString(),
      surgeMultiplier: _tryParseDouble(json['surge_multiplier']),
      pickupTimestamp: _parseTimestamp(
        json['pickup'] is Map
            ? (json['pickup'] as Map)['timestamp']
            : json['pickup_timestamp'],
      ),
      dropoffTimestamp: _parseTimestamp(
        json['dropoff'] is Map
            ? (json['dropoff'] as Map)['timestamp']
            : json['dropoff_timestamp'],
      ),
      startCity:
          json['start_city'] is Map<String, dynamic>
              ? DriverTripCity.fromJson(
                json['start_city'] as Map<String, dynamic>,
              )
              : null,
      statusChanges: statusChanges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'status': status,
      'duration': durationSeconds,
      'distance': distance,
      'fare': fare,
      'currency_code': currencyCode,
      'surge_multiplier': surgeMultiplier,
      'pickup_timestamp': pickupTimestamp?.toUtc().millisecondsSinceEpoch,
      'dropoff_timestamp': dropoffTimestamp?.toUtc().millisecondsSinceEpoch,
      'start_city': startCity?.toJson(),
      'status_changes': statusChanges.map((item) => item.toJson()).toList(),
    };
  }

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseTimestamp(dynamic value) {
    final seconds = _tryParseInt(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}

class DriverTripStatusChange {
  DriverTripStatusChange({required this.status, this.timestamp});

  final String status;
  final DateTime? timestamp;

  factory DriverTripStatusChange.fromJson(Map<String, dynamic> json) {
    return DriverTripStatusChange(
      status: json['status']?.toString() ?? '',
      timestamp: DriverTripModel._parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp?.toUtc().millisecondsSinceEpoch,
    };
  }
}

class DriverTripCity {
  DriverTripCity({this.displayName, this.latitude, this.longitude});

  final String? displayName;
  final double? latitude;
  final double? longitude;

  factory DriverTripCity.fromJson(Map<String, dynamic> json) {
    return DriverTripCity(
      displayName: json['display_name']?.toString(),
      latitude: DriverTripModel._tryParseDouble(json['latitude']),
      longitude: DriverTripModel._tryParseDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
