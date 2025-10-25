class DriverProfileModel {
  DriverProfileModel({
    required this.driverId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.picture,
    this.promoCode,
    this.rating,
    this.activationStatus,
  });

  final String driverId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? picture;
  final String? promoCode;
  final double? rating;
  final String? activationStatus;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      driverId: json['driver_id']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      picture: json['picture']?.toString(),
      promoCode: json['promo_code']?.toString(),
      rating: _tryParseDouble(json['rating']),
      activationStatus: json['activation_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'picture': picture,
      'promo_code': promoCode,
      'rating': rating,
      'activation_status': activationStatus,
    };
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
