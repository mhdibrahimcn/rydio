enum RideOption { all, bikes, autos, cabs }

extension RideOptionExtension on RideOption {
  String get displayName {
    switch (this) {
      case RideOption.all:
        return 'All';
      case RideOption.bikes:
        return 'Bikes';
      case RideOption.autos:
        return 'Autos';
      case RideOption.cabs:
        return 'Cabs';
    }
  }

  String get icon {
    switch (this) {
      case RideOption.all:
        return '🚗';
      case RideOption.bikes:
        return '🏍️';
      case RideOption.autos:
        return '🛺';
      case RideOption.cabs:
        return '🚕';
    }
  }
}
