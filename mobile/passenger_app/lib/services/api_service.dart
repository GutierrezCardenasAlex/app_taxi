import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

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
}

