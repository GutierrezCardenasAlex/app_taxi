import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    await Geolocator.requestPermission();
    return Geolocator.getCurrentPosition();
  }
}

