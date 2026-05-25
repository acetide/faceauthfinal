import 'package:dio/dio.dart';

/// Singleton service for API configuration and token management.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        // Ganti apabila IP berubah
        baseUrl: 'http:// 192.168.3.102:5298',
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Sets the authorization token for API requests.
  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
/// Clears the authorization token.
  
  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}