import 'dart:convert';
import 'comment_model.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final String? imagePath; // File path (web: /uploads/announcements/, FILEAPI: C:\FILEAPI\announcements\)
  final String? imageFileName; // Original filename
  final String? imageContentType; // MIME type (image/jpeg, image/png, etc.)
  final List<Comment> comments;

  Announcement({
    this.id = '',
    required this.title,
    required this.description,
    this.imagePath,
    this.imageFileName,
    this.imageContentType,
    List<Comment>? comments,
  }) : comments = comments ?? const [];

  /// Factory constructor to create Announcement from JSON.
  factory Announcement.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'];
    final comments = <Comment>[];

    if (rawComments is List) {
      for (var item in rawComments) {
        if (item == null) continue;
        comments.add(Comment.fromJson(item));
      }
    } else if (rawComments is String && rawComments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawComments) as List<dynamic>?;
        if (decoded != null) {
          for (var item in decoded) {
            if (item == null) continue;
            comments.add(Comment.fromJson(item));
          }
        }
      } catch (_) {
        comments.add(Comment.fromJson(rawComments));
      }
    }

    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'],
      imageFileName: json['imageFileName'],
      imageContentType: json['imageContentType'],
      comments: comments,
    );
  }

  /// Converts Announcement to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imagePath': imagePath,
        'imageFileName': imageFileName,
        'imageContentType': imageContentType,
        'comments': comments.map((comment) => comment.toJson()).toList(),
      };
}

