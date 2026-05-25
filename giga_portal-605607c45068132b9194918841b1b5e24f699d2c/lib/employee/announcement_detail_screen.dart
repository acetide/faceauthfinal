import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import 'dart:typed_data';
import '../services/employee_profile_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;
  final User? user;

  const AnnouncementDetailScreen({super.key, required this.announcement, this.user});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final TextEditingController commentController = TextEditingController();
  bool _isSubmitting = false;

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl = ApiService().dio.options.baseUrl;
    return '$baseUrl$imagePath';
  }

  Widget _buildCommentAvatar(Comment comment) {
    if (comment.authorId == null || comment.authorId!.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE8EAF6),
        child: const Icon(Icons.person, size: 20),
      );
    }

    return FutureBuilder<Uint8List>(
      future: EmployeeProfileService().getEmployeeProfilePicture(comment.authorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8EAF6),
            child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8EAF6),
            child: const Icon(Icons.person, size: 20),
          );
        }

        return CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE8EAF6),
          child: ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Future<void> addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = Comment(
        id: '',
        message: text,
        authorName: widget.user?.name ?? 'Unknown',
        authorId: widget.user?.kodeNik,
      );

      await AnnouncementService().addComment(
        announcementId: widget.announcement.id,
        message: text,
        authorName: comment.authorName,
        authorId: comment.authorId ?? '',
      );

      if (!mounted) return;

      setState(() {
        widget.announcement.comments.add(comment);
        commentController.clear();
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment added')));
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showImagePreview() {
    final imagePath = widget.announcement.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image available')));
      return;
    }

    final imageUrl = _buildImageUrl(imagePath);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            imageUrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;

    return Scaffold(
      appBar: AppBar(title: Text(announcement.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.imagePath != null)
              GestureDetector(
                onTap: _showImagePreview,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.network(
                        _buildImageUrl(announcement.imagePath),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(0),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              announcement.description,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),
            const Divider(),

            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: announcement.comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      itemCount: announcement.comments.length,
                      itemBuilder: (ctx, idx) {
                        final comment = announcement.comments[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCommentAvatar(comment),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  comment.authorName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (comment.authorId != null &&
                                                  comment.authorId == widget.user?.kodeNik)
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () async {
                                                    if (!mounted) return;
                                                    final messenger = ScaffoldMessenger.of(context);
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Delete comment'),
                                                        content: const Text(
                                                          'Are you sure you want to delete this comment?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, false),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, true),
                                                            child: const Text('Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (confirmed != true) return;

                                                    try {
                                                      await AnnouncementService().deleteComment(
                                                        commentId: comment.id,
                                                        authorId: widget.user?.kodeNik ?? '',
                                                      );

                                                      if (!mounted) return;

                                                      setState(() {
                                                        widget.announcement.comments.remove(comment);
                                                      });

                                                      messenger.showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Comment deleted'),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      if (!mounted) return;
                                                      messenger.showSnackBar(
                                                        SnackBar(content: Text('Error: $e')),
                                                      );
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                          Text(
                                            '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(comment.message),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : addComment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
