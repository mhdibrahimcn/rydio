enum ServiceName { uber, ola, rapido }

enum CabType { bike, auto, cab, pool }

class FareModel {
  final ServiceName serviceName;
  final String cabType;
  final CabType category;
  final double price;
  final int eta; // in minutes
  final int seats;
  final bool isBestPrice;
  final String? deepLinkUrl;

  FareModel({
    required this.serviceName,
    required this.cabType,
    required this.category,
    required this.price,
    required this.eta,
    required this.seats,
    this.isBestPrice = false,
    this.deepLinkUrl,
  });

  factory FareModel.fromJson(Map<String, dynamic> json) {
    return FareModel(
      serviceName: ServiceName.values.firstWhere(
        (e) => e.toString().split('.').last == json['serviceName'],
        orElse: () => ServiceName.uber,
      ),
      cabType: json['cabType'] ?? '',
      category: CabType.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => CabType.cab,
      ),
      price: (json['price'] ?? 0.0).toDouble(),
      eta: json['eta'] ?? 0,
      seats: json['seats'] ?? 1,
      isBestPrice: json['isBestPrice'] ?? false,
      deepLinkUrl: json['deepLinkUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceName': serviceName.toString().split('.').last,
      'cabType': cabType,
      'category': category.toString().split('.').last,
      'price': price,
      'eta': eta,
      'seats': seats,
      'isBestPrice': isBestPrice,
      'deepLinkUrl': deepLinkUrl,
    };
  }

  String get serviceDisplayName {
    switch (serviceName) {
      case ServiceName.uber:
        return 'Uber';
      case ServiceName.ola:
        return 'Ola';
      case ServiceName.rapido:
        return 'Rapido';
    }
  }

  String get serviceIcon {
    switch (serviceName) {
      case ServiceName.uber:
        return '🚗';
      case ServiceName.ola:
        return '🚕';
      case ServiceName.rapido:
        return '🏍️';
    }
  }

  String get categoryIcon {
    switch (category) {
      case CabType.bike:
        return '🏍️';
      case CabType.auto:
        return '🛺';
      case CabType.cab:
        return '🚗';
      case CabType.pool:
        return '🚗';
    }
  }

  @override
  String toString() {
    return 'FareModel($serviceDisplayName $cabType - ₹$price - ${eta}min)';
  }
}
