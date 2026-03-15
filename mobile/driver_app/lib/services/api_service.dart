import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

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
}

