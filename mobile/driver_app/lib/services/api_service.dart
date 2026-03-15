import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  Future<Response<dynamic>> sendOtp(String phoneNumber) {
    return _dio.post('/auth/send-otp', data: {'phoneNumber': phoneNumber, 'role': 'driver'});
  }

  Future<Response<dynamic>> verifyOtp(String phoneNumber, String otp) {
    return _dio.post('/auth/verify-otp', data: {'phoneNumber': phoneNumber, 'otp': otp});
  }

  Future<Response<dynamic>> fetchMe(String token) {
    return _dio.get('/auth/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response<dynamic>> fetchDriverProfile(String token) {
    return _dio.get('/driver/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response<dynamic>> updateStatus(String token, String status) {
    return _dio.post(
      '/driver/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> sendLocation(String token, Map<String, dynamic> payload) {
    return _dio.post(
      '/driver/location',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> fetchOffers(String token) {
    return _dio.get('/driver/offers', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response<dynamic>> fetchActiveTrip(String token) {
    return _dio.get('/driver/active-trip', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response<dynamic>> fetchDriverHistory(String token) {
    return _dio.get('/driver/history', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response<dynamic>> acceptTrip(String token, String tripId, String driverId) {
    return _dio.post(
      '/trip/accept',
      data: {'tripId': tripId, 'driverId': driverId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> startTrip(String token, String tripId) {
    return _dio.post(
      '/trip/start',
      data: {'tripId': tripId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> endTrip(String token, String tripId, double finalFare) {
    return _dio.post(
      '/trip/end',
      data: {'tripId': tripId, 'finalFare': finalFare},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> markArrived(String token, String tripId) {
    return _dio.post(
      '/trip/arrived',
      data: {'tripId': tripId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
