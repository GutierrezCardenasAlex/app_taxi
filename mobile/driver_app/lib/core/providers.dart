import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final socketServiceProvider = Provider((ref) => SocketService());
final locationServiceProvider = Provider((ref) => LocationService());

final authProvider = StateProvider<String?>((ref) => null);
final driverProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final tripProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final locationProvider = StateProvider<Map<String, double>?>((ref) => null);

