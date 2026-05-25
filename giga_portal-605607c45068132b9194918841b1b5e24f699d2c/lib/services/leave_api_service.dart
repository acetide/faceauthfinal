import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:giga_portal/models/leave_request.dart';
import 'package:giga_portal/services/api_service.dart';
import 'package:giga_portal/utils/dio_error_handler.dart';

class LeaveApiService {
  static const String _baseEndpoint = '/Api/Mobile/Portal';

  /// Get all leave requests
  static Future<List<LeaveRequest>> getLeaveRequests() async {
    try {
      final response = await ApiService().dio.get(
        '$_baseEndpoint/GetLeaveRequests',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => LeaveRequest.fromJson(e))
              .toList();
        }
      }
      throw Exception('Failed to load leave requests');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Submit a new leave request (multipart/form-data)
  static Future<LeaveRequest> createLeaveRequest(
    String kodeNik,
    int durationDays,
    String reason,
    DateTime startDate,
    DateTime endDate,
    String leaveType,
    File? attachmentFile,
  ) async {
    try {
      final formData = FormData.fromMap({
        'KodeNik': kodeNik,
        'LamaHari': durationDays,
        'Keterangan': reason,
        'TanggalMulai': startDate.toIso8601String(),
        'TanggalSelesai': endDate.toIso8601String(),
        'JenisPengajuan': leaveType,

        // ✅ OPTIONAL FILE
        if (attachmentFile != null)
          'FileLampiran': await MultipartFile.fromFile(
            attachmentFile.path,
            filename: attachmentFile.path.split('/').last,
          ),
      });

      final response = await ApiService().dio.post(
        '$_baseEndpoint/CreateLeaveRequest',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return LeaveRequest.fromJson(data['data']);
        }
      }

      throw Exception('Failed to create leave request');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Approve leave request
  static Future<LeaveRequest> approveLeaveRequest(String id) async {
    try {
      final response = await ApiService().dio.post(
        '$_baseEndpoint/ApproveLeave',
        data: {'Id': id},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return LeaveRequest.fromJson(data['data']);
        }
      }
      throw Exception('Failed to approve leave request');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Reject leave request with reason
  static Future<LeaveRequest> rejectLeaveRequest(
    String id,
    String reason,
  ) async {
    try {
      final response = await ApiService().dio.post(
        '$_baseEndpoint/RejectLeave',
        data: {
          'Id': id,
          'RejectionReason': reason,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return LeaveRequest.fromJson(data['data']);
        }
      }
      throw Exception('Failed to reject leave request');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Get leave request attachment from web server (uploads/pengajuan)
  static Future<Uint8List> getLeaveAttachmentFromWeb(String id) async {
    try {
      final response = await ApiService().dio.get(
        '$_baseEndpoint/GetLeaveAttachment/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data as List<int>);
      }
      throw Exception('Failed to download from web');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Get leave request attachment from FILEAPI folder
  static Future<Uint8List> getLeaveAttachmentFromFileAPI(String id) async {
    try {
      final response = await ApiService().dio.get(
        '$_baseEndpoint/GetLeaveAttachmentFromFileAPI/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data as List<int>);
      }
      throw Exception('Failed to download from FILEAPI');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
