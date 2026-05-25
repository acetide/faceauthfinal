import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  Future<(String, User)> login({
    required String userName,
    required String password,
  }) async {
    try {
      final response = await ApiService().dio.post(
        '/Api/Mobile/Login',
        data: {
          'userName': userName,
          'password': password,
        },
      );

      // Check if response indicates an error
      if (response.data['status'] == 'error') {
        throw Exception(response.data['message'] ?? 'Login failed');
      }

      final String token = response.data['token'] as String;

      final User user = User.fromJson(
        response.data['userData'] as Map<String, dynamic>,
      );

      /// SAVE TOKEN 
      ApiService().setToken(token);

      return (token, user);
    } on DioException catch (e) {
      // Extract error message from response if available
      if (e.response?.data != null && e.response?.data is Map) {
        final message = e.response?.data['message'] ?? e.response?.data['Message'];
        if (message != null) {
          throw Exception(message);
        }
      }
      
      // Handle connection errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your network.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please check your network or server address.');
      }
      
      throw Exception(e.message ?? 'Login failed');
    } catch (e) {
      rethrow;
    }
  }
}
