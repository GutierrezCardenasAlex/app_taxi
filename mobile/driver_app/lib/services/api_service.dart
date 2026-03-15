import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

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
