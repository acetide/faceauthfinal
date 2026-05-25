import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveRequest leave;

  const LeaveDetailScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(leave.submissionStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leave.submissionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Employee Info
            _buildDetailCard(
              'Employee Code',
              leave.employeeCode,
              Icons.person,
            ),
            const SizedBox(height: 12),

            // Leave Type
            _buildDetailCard(
              'Leave Type',
              leave.submissionType,
              Icons.event_note,
            ),
            const SizedBox(height: 12),

            // Duration
            _buildDetailCard(
              'Duration',
              '${leave.durationDays} day(s)',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),

            // Start Date
            _buildDetailCard(
              'Start Date',
              leave.startDate.toLocal().toIso8601String().split('T').first,
              Icons.date_range,
            ),
            const SizedBox(height: 12),

            // End Date
            _buildDetailCard(
              'End Date',
              leave.endDate.toLocal().toIso8601String().split('T').first,
              Icons.date_range,
            ),
            const SizedBox(height: 12),

            // Description/Reason
            _buildDetailCard(
              'Reason',
              leave.description,
              Icons.description,
              multiline: true,
            ),
            const SizedBox(height: 12),

            // Submission Date
            _buildDetailCard(
              'Submitted On',
              leave.submissionDate.toLocal().toIso8601String().split('T').first,
              Icons.access_time,
            ),

            // Approval Date 
            if (leave.approvalDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailCard(
                'Approved On',
                leave.approvalDate!.toLocal().toIso8601String().split('T').first,
                Icons.check_circle,
              ),
            ],

            // Rejection Reason
            if (leave.rejectionReason != null && leave.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailCard(
                'Rejection Reason',
                leave.rejectionReason!,
                Icons.error,
                multiline: true,
              ),
            ],

            // Attachment
            if (leave.attachmentFile != null || leave.attachmentUrl != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  if (leave.attachmentFile != null) {
                    _openAttachment(context, leave.attachmentFile!);
                  } else if (leave.attachmentUrl != null) {
                    _showAttachmentSourceDialog(context, leave.id, leave.attachmentName);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              leave.attachmentUrl != null ? (leave.attachmentName ?? 'Server file') : _buildAttachmentSubtitle(leave),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: Colors.blueGrey),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ID (for reference)
            Text(
              'Request ID: ${leave.id}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon, {
    bool multiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: multiline ? 5 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openAttachment(BuildContext context, Uint8List bytes) async {
    if (_shouldPreviewInline(bytes)) {
      _openImagePreview(context, bytes);
      return;
    }

    final fileName = _buildAttachmentFileName();
    final filePath = await _writeToTempFile(bytes, fileName);
    if (filePath == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment file.')),
      );
      return;
    }

    await OpenFilex.open(filePath);
  }

  bool _shouldPreviewInline(Uint8List bytes) {
    // Trust contentType first — if server says it's an image, preview it
    if (leave.attachmentContentType != null) {
      final ct = leave.attachmentContentType!.toLowerCase();
      return ct.startsWith('image/');
    }

    // Fallback: check magic numbers for common formats
    if (bytes.lengthInBytes < 2) return false;
    final header = bytes.sublist(0, 12.clamp(0, bytes.length));

    // PNG: 89 50 4E 47
    if (header.length >= 4 &&
        header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47) {
      return true;
    }
    // JPEG: FF D8
    if (header.length >= 2 && header[0] == 0xFF && header[1] == 0xD8) return true;
    // GIF: 47 49 46 (GIF87a or GIF89a)
    if (header.length >= 3 && header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) return true;
    // BMP: 42 4D
    if (header.length >= 2 && header[0] == 0x42 && header[1] == 0x4D) return true;
    // WebP: RIFF....WEBP (check for WEBP at offset 8)
    if (header.length >= 12 &&
        header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
        header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50) {
      return true;
    }

    return false;
  }

  String _buildAttachmentSubtitle(LeaveRequest leave) {
    final size = leave.attachmentFile?.length ?? 0;
    final sizeLabel = '${(size / 1024).toStringAsFixed(1)} KB';
    final name = leave.attachmentName;
    if (name != null && name.isNotEmpty) {
      return '$name · $sizeLabel · Tap to open';
    }
    return '$sizeLabel · Tap to open';
  }

  String _buildAttachmentFileName() {
    final name = leave.attachmentName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final type = leave.attachmentContentType ?? '';
    final extension = _extensionFromContentType(type);
    return 'leave-attachment-${DateTime.now().millisecondsSinceEpoch}$extension';
  }

  String _extensionFromContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'application/pdf':
        return '.pdf';
      case 'application/msword':
        return '.doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return '.docx';
      case 'image/png':
        return '.png';
      case 'image/jpeg':
        return '.jpg';
      default:
        return '';
    }
  }

  Future<String?> _writeToTempFile(Uint8List bytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadAndOpenFromServer(BuildContext context, String id, String? filename) async {
    try {
      final resp = await ApiService().dio.get(
        '/Api/Mobile/Portal/GetLeaveAttachment/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(resp.data as List<int>);
      final name = filename ?? 'attachment-${DateTime.now().millisecondsSinceEpoch}';

      // Check if it's an image — if so, preview inline instead of opening with external app
      if (leave.attachmentContentType != null &&
          leave.attachmentContentType!.toLowerCase().startsWith('image/')) {
        if (!context.mounted) return;
        _openImagePreview(context, bytes);
        return;
      }

      // For non-images, save to temp and open with default app
      final filePath = await _writeToTempFile(bytes, name);
      if (filePath == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to download attachment.')));
        return;
      }

      await OpenFilex.open(filePath);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading attachment: $e')));
    }
  }

  /// Show a dialog to choose between web uploads or FILEAPI sources
  void _showAttachmentSourceDialog(BuildContext context, String id, String? filename) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Attachment'),
        content: const Text('Choose where to download the attachment from:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndOpenFromServer(context, id, filename);
            },
            child: const Text('Web Server'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndOpenFromFileAPI(context, id, filename);
            },
            child: const Text('FILEAPI Folder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Download attachment from FILEAPI folder
  Future<void> _downloadAndOpenFromFileAPI(BuildContext context, String id, String? filename) async {
    try {
      final resp = await ApiService().dio.get(
        '/Api/Mobile/Portal/GetLeaveAttachmentFromFileAPI/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(resp.data as List<int>);
      final name = filename ?? 'attachment-${DateTime.now().millisecondsSinceEpoch}';

      // Check if it's an image — if so, preview inline instead of opening with external app
      if (leave.attachmentContentType != null &&
          leave.attachmentContentType!.toLowerCase().startsWith('image/')) {
        if (!context.mounted) return;
        _openImagePreview(context, bytes);
        return;
      }

      // For non-images, save to temp and open with default app
      final filePath = await _writeToTempFile(bytes, name);
      if (filePath == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to download from FILEAPI.')));
        return;
      }

      await OpenFilex.open(filePath);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading from FILEAPI: $e'),
          action: SnackBarAction(
            label: 'Try Web',
            onPressed: () => _downloadAndOpenFromServer(context, id, filename),
          ),
        ),
      );
    }
  }

  void _openImagePreview(BuildContext context, Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: const Text(
                'Attachment Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to preview this attachment as an image. (${bytes.length} bytes)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
