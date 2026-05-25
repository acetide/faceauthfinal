import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import 'announcement_card.dart';

class AnnouncementFeed extends StatelessWidget {
  final List<Announcement> announcements;
  final User? user;

  const AnnouncementFeed({
    super.key,
    required this.announcements,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const Center(
        child: Text('No announcements yet'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.campaign, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        ...announcements.map((a) => AnnouncementCard(announcement: a, user: user)),
      ],
    );
  }
}
