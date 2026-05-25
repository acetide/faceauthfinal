import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../employee/announcement_detail_screen.dart';
import '../services/api_service.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final User? user;

  const AnnouncementCard({super.key, required this.announcement, this.user});

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl = ApiService().dio.options.baseUrl;
    return '$baseUrl$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnnouncementDetailScreen(
                announcement: announcement,
                user: user,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _buildImageUrl(announcement.imagePath),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          announcement.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${announcement.comments.length} Comment${announcement.comments.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
