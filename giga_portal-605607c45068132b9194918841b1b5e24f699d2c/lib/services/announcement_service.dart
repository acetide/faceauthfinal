import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/announcement_model.dart';
import 'api_service.dart';
import '../utils/dio_error_handler.dart';

class AnnouncementService {
  /// Get all announcements
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await ApiService().dio.get(
        '/Api/Mobile/Portal/GetAnnouncements',
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map<Announcement>((a) => Announcement.fromJson(a)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new announcement with image file
  Future<Announcement> createAnnouncement({
    required String title,
    required String description,
    File? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        if (imageFile != null)
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      final response = await ApiService().dio.post(
        '/Api/Mobile/Portal/CreateAnnouncement',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data['data'];
      return Announcement.fromJson(data);
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Add comment
  Future<void> addComment({
    required String announcementId,
    required String message,
    required String authorName,
    required String authorId,
  }) async {
    try {
      await ApiService().dio.post(
        '/Api/Mobile/Portal/AddComment',
        data: {
          'announcementId': announcementId,
          'message': message,
          'authorName': authorName,
          'authorId': authorId,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete comment by ID
  Future<void> deleteComment({
    required String commentId,
    required String authorId,
  }) async {
    try {
      await ApiService().dio.delete(
        '/Api/Mobile/Portal/DeleteComment',
        data: {
          'commentId': commentId,
          'authorId': authorId,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Download announcement image from web server
  Future<Uint8List> getAnnouncementImage(String id) async {
    try {
      final response = await ApiService().dio.get(
        '/Api/Mobile/Portal/GetAnnouncementImage/$id',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Download announcement image from FILEAPI folder
  Future<Uint8List> getAnnouncementImageFromFileAPI(String id) async {
    try {
      final response = await ApiService().dio.get(
        '/Api/Mobile/Portal/GetAnnouncementImageFromFileAPI/$id',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      rethrow;
    }
  }
}
