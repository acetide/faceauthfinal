import 'dart:convert';

import 'package:dio/dio.dart';

String handleDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    return 'Connection timeout';
  }

  if (e.response != null) {
    final data = e.response?.data;

    // Prefer common server fields
    if (data is Map) {
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      // fallback: return full data as JSON string for debugging
      try {
        return jsonEncode(data);
      } catch (_) {
        return data.toString();
      }
    }

    // If response data is raw string
    return data?.toString() ?? 'Server error';
  }

  return 'Something went wrong';
}
