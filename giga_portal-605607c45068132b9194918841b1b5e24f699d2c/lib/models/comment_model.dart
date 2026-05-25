/// Model representing a comment on an announcement.
class Comment {
  final String id;
  final String message;
  final String authorName;
  final String? authorId;
  final DateTime createdAt;

  Comment({
    this.id = '',
    required this.message,
    required this.authorName,
    this.authorId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory constructor to create Comment from JSON or legacy string values.
  factory Comment.fromJson(dynamic json) {
    if (json is String) {
      return Comment(
        message: json,
        authorName: 'Unknown',
      );
    }

    if (json is Map<String, dynamic>) {
      return Comment(
        id: json['commentId']?.toString() ?? json['id']?.toString() ?? '',
        message: json['message'] ?? '',
        authorName: json['authorName'] ?? 'Unknown',
        authorId: json['authorId'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }

    return Comment(
      message: json?.toString() ?? '',
      authorName: 'Unknown',
    );
  }

  /// Converts Comment to JSON map.
  Map<String, dynamic> toJson() => {
        'commentId': id,
        'message': message,
        'authorName': authorName,
        'authorId': authorId,
        'createdAt': createdAt.toIso8601String(),
      };
}
