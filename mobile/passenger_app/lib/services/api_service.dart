import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  Future<Response<dynamic>> sendOtp(String phoneNumber) {
    return _dio.post('/auth/send-otp', data: {'phoneNumber': phoneNumber, 'role': 'passenger'});
  }

  Future<Response<dynamic>> verifyOtp(String phoneNumber, String otp) {
    return _dio.post('/auth/verify-otp', data: {'phoneNumber': phoneNumber, 'otp': otp});
  }

  Future<Response<dynamic>> requestTrip(Map<String, dynamic> payload, String token) {
    return _dio.post(
      '/trip/request',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> fetchTripHistory(String token) {
    return _dio.get(
      '/trip/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> fetchTripStatus(String tripId, String token) {
    return _dio.get(
      '/trip/status/$tripId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> fetchCurrentTrip(String token) {
    return _dio.get(
      '/trip/current',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> fetchMe(String token) {
    return _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> updateProfile(String token, String fullName) {
    return _dio.put(
      '/auth/profile',
      data: {'fullName': fullName},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> updateSettings(String token, Map<String, dynamic> payload) {
    return _dio.put(
      '/auth/settings',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
