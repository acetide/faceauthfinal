import 'dart:convert';
import 'dart:typed_data';

/// Model representing a leave request with attachment handling.
class LeaveRequest {
  final String employeeCode;
  final String id;
  final int durationDays;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final Uint8List? attachmentFile;
  final String? attachmentName;
  final String? attachmentContentType;
  final String? attachmentUrl; // server path when file is stored on server
  final String submissionType; // e.g., "Sick", "Annual"
  String submissionStatus; // Pending, Accepted, Rejected
  String? rejectionReason;
  DateTime? approvalDate;
  final DateTime submissionDate;

  /// Constructor for LeaveRequest.
  LeaveRequest({
    required this.employeeCode,
    String? id,
    required this.durationDays,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.attachmentFile,
    this.attachmentName,
    this.attachmentContentType,
    this.attachmentUrl,
    required this.submissionType,
    this.submissionStatus = 'Pending',
    this.rejectionReason,
    this.approvalDate,
    DateTime? submissionDate,
  })  : id = id ?? DateTime.now().toIso8601String(),
        submissionDate = submissionDate ?? DateTime.now();
/// Converts LeaveRequest to JSON map for API submission.
  
  Map<String, dynamic> toJson() => {
        'KodeNik': employeeCode,
        'id': id,
        'LamaHari': durationDays,
        'Keterangan': description,
        'TanggalMulai': startDate.toIso8601String(),
        'TanggalSelesai': endDate.toIso8601String(),
        // If we have raw bytes, encode to base64. Otherwise if we have an attachmentUrl (server path), save that.
        'FileLampiran': attachmentFile != null
            ? base64Encode(attachmentFile!)
            : attachmentUrl,
        'FileLampiranName': attachmentName,
        'FileLampiranType': attachmentContentType,
        'JenisPengajuan': submissionType,
        'StatusPengajuan': submissionStatus,
        'AlasanPenolakan': rejectionReason,
        'TanggalPersetujuan': approvalDate?.toIso8601String(),
        'TanggalPengajuan': submissionDate.toIso8601String(),
      };
/// Factory constructor to create LeaveRequest from JSON, handling Base64 or URL attachments.
  
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    // Handle FileLampiran which can be either base64-encoded bytes or a server path
    final fileLampiran = json['FileLampiran'] as String?;
    Uint8List? attachmentBytes;
    String? attachmentUrl;
    if (fileLampiran != null) {
      // Heuristic: treat as URL/path if it contains a slash or starts with '/'
      if (fileLampiran.contains('/') || fileLampiran.startsWith('/')) {
        attachmentUrl = fileLampiran;
      } else {
        try {
          attachmentBytes = base64Decode(fileLampiran);
        } catch (_) {
          // not valid base64, treat as URL
          attachmentUrl = fileLampiran;
        }
      }
    }

    return LeaveRequest(
      employeeCode: (json['KodeNik'] ?? json['employeeCode'] ?? '') as String,
      id: (json['id'] ?? '') as String,
      durationDays: (json['LamaHari'] ?? json['durationDays'] ?? 0) as int,
      description: (json['Keterangan'] ?? json['description'] ?? '') as String,
      startDate: DateTime.parse((json['TanggalMulai'] ?? json['startDate'] ?? DateTime.now().toIso8601String()).toString()),
      endDate: DateTime.parse((json['TanggalSelesai'] ?? json['endDate'] ?? DateTime.now().toIso8601String()).toString()),
      attachmentFile: attachmentBytes,
      attachmentName: json['FileLampiranName'] ?? json['attachmentName'],
      attachmentContentType: json['FileLampiranType'] ?? json['attachmentContentType'],
      attachmentUrl: attachmentUrl,
      submissionType: (json['JenisPengajuan'] ?? json['submissionType'] ?? 'Other') as String,
      submissionStatus: (json['StatusPengajuan'] ?? json['submissionStatus'] ?? 'Pending') as String,
      rejectionReason: json['AlasanPenolakan'] ?? json['rejectionReason'],
      approvalDate: json['TanggalPersetujuan'] != null ? DateTime.parse(json['TanggalPersetujuan'].toString()) : null,
      submissionDate: json['TanggalPengajuan'] != null ? DateTime.parse(json['TanggalPengajuan'].toString()) : DateTime.now(),
    );
  }
}
