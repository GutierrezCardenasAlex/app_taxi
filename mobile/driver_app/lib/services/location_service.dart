import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position> track() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 5),
    );
  }
}

