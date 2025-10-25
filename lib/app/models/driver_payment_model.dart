class DriverPaymentModel {
  DriverPaymentModel({
    required this.paymentId,
    this.category,
    this.tripId,
    this.eventTime,
    this.cashCollected,
    this.amount,
    this.driverId,
    this.partnerId,
    this.currencyCode,
    this.breakdown = const {},
    this.riderFees = const {},
  });

  final String paymentId;
  final String? category;
  final String? tripId;
  final DateTime? eventTime;
  final double? cashCollected;
  final double? amount;
  final String? driverId;
  final String? partnerId;
  final String? currencyCode;
  final Map<String, double> breakdown;
  final Map<String, double> riderFees;

  factory DriverPaymentModel.fromJson(Map<String, dynamic> json) {
    return DriverPaymentModel(
      paymentId: json['payment_id']?.toString() ?? '',
      category: json['category']?.toString(),
      tripId: json['trip_id']?.toString(),
      eventTime: _parseTimestamp(json['event_time']),
      cashCollected: _tryParseDouble(json['cash_collected']),
      amount: _tryParseDouble(json['amount']),
      driverId: json['driver_id']?.toString(),
      partnerId: json['partner_id']?.toString(),
      currencyCode: json['currency_code']?.toString(),
      breakdown: _parseDoubleMap(json['breakdown']),
      riderFees: _parseDoubleMap(json['rider_fees']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'category': category,
      'trip_id': tripId,
      'event_time': eventTime?.toUtc().millisecondsSinceEpoch,
      'cash_collected': cashCollected,
      'amount': amount,
      'driver_id': driverId,
      'partner_id': partnerId,
      'currency_code': currencyCode,
      'breakdown': breakdown,
      'rider_fees': riderFees,
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    final seconds = _tryParseInt(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
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

  static Map<String, double> _parseDoubleMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        final parsed = _tryParseDouble(val) ?? 0;
        return MapEntry(key.toString(), parsed);
      });
    }
    return const {};
  }
}
