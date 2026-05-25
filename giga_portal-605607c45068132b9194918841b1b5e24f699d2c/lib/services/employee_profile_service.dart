import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/dio_error_handler.dart';

/// Service for managing employee profile pictures
class EmployeeProfileService {
  /// Upload employee profile picture (admin only)
  /// Returns the path where the image was saved
  Future<String> uploadEmployeeProfilePicture({
    required String employeeKodeNik,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'employeeKodeNik': employeeKodeNik,
        'profileImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await ApiService().dio.post(
        '/Api/Mobile/AdminUploadEmployeeProfilePicture',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['profilePath'] ?? '';
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload profile picture');
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Download employee profile picture from FileAPI
  Future<Uint8List> getEmployeeProfilePicture(String employeeKodeNik) async {
    try {
      var path = '/Api/Mobile/GetEmployeeProfilePictureFromFileAPI/$employeeKodeNik';
      // Add cache-busting query param so updated images are fetched after upload
      final ts = DateTime.now().millisecondsSinceEpoch;
      path = '$path?t=$ts';

      final response = await ApiService().dio.get(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Get URL for employee profile picture
  String getEmployeeProfilePictureUrl(String employeeKodeNik, {bool cacheBust = true}) {
    final baseUrl = ApiService().dio.options.baseUrl;
    var url = '$baseUrl/Api/Mobile/GetEmployeeProfilePictureFromFileAPI/$employeeKodeNik';
    if (cacheBust) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      url = '$url?t=$ts';
    }
    return url;
  }
}
