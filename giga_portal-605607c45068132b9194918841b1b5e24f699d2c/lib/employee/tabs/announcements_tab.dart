import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../models/user_model.dart';
import '../../employee/announcement_detail_screen.dart';
import '../../services/api_service.dart';

class AnnouncementsTab extends StatefulWidget {
  final List<Announcement> announcements;
  final User? user;

  const AnnouncementsTab({super.key, required this.announcements, this.user});

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  final Map<String, bool> _expanded = {};

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl = ApiService().dio.options.baseUrl;
    return '$baseUrl$imagePath';
  }

  Color _badgeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.redAccent;
      case 'success':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = widget.announcements;

    if (announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.campaign,
                size: 56,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.2 * 255).round()),
              ),
              const SizedBox(height: 12),
              Text(
                'No announcements yet',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = announcements[index];
        final isExpanded = _expanded[a.id] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetailScreen(
                    announcement: a,
                    user: widget.user,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _buildImageUrl(a.imagePath),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _badgeColor('info'),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'info',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Date: —',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${a.comments.length} Comment${a.comments.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _expanded[a.id] = !(isExpanded)),
                        child: Text(
                          isExpanded ? 'Hide' : 'View',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded && a.comments.isNotEmpty)
                    Column(
                      children: a.comments
                          .map(
                            (c) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.message),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
