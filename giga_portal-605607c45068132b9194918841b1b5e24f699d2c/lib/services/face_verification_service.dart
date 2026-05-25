import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_service.dart';
import '../utils/dio_error_handler.dart';

class FaceVerificationResult {
  final bool success;
  final bool verified;
  final double score;
  final String message;

  FaceVerificationResult({
    required this.success,
    required this.verified,
    required this.score,
    required this.message,
  });
}

class FaceVerificationService {
  final Dio _dio = ApiService().dio;

  Future<String> storeFaceReference({
    required String employeeKodeNik,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'faceImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _dio.post(
        '/Api/Mobile/Portal/StoreFaceReference/$employeeKodeNik',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['message'] ?? 'Face reference stored successfully.';
      }

      throw Exception(response.data['message'] ?? 'Failed to store face reference.');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<FaceVerificationResult> verifyFaceAgainstEmployee({
    required String employeeKodeNik,
    required File probeImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'employeeKodeNik': employeeKodeNik,
        'probeImage': await MultipartFile.fromFile(
          probeImage.path,
          filename: probeImage.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _dio.post(
        '/Api/Mobile/Portal/VerifyFaceAgainstEmployee',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data as Map<String, dynamic>;
      return FaceVerificationResult(
        success: data['success'] == true,
        verified: data['match'] == true,
        score: (data['score'] is num) ? (data['score'] as num).toDouble() : 0.0,
        message: data['message']?.toString() ?? 'Verification completed.',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<Uint8List> getEmployeeFaceReference(String employeeKodeNik) async {
    try {
      final response = await _dio.get(
        '/Api/Mobile/Portal/GetEmployeeFaceReference/$employeeKodeNik',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  String getEmployeeFaceReferenceUrl(String employeeKodeNik, {bool cacheBust = true}) {
    final baseUrl = ApiService().dio.options.baseUrl;
    var url = '$baseUrl/Api/Mobile/Portal/GetEmployeeFaceReference/$employeeKodeNik';
    if (cacheBust) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      url = '$url?t=$ts';
    }
    return url;
  }
}
