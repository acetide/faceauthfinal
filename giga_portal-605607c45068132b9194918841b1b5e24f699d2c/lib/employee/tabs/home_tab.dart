import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/announcement_model.dart';
import '../../widgets/user_info_card.dart';
import '../../widgets/announcement_feed.dart';
import '../../screens/leave_request_screen.dart';
import '../../widgets/clock_in_widget.dart';


class HomeTab extends StatelessWidget {
  final User user;
  final List<Announcement> announcements;

  const HomeTab({
    super.key,
    required this.user,
    required this.announcements,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnnouncementFeed(announcements: announcements, user: user),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        UserInfoCard(user: user),
                        const SizedBox(height: 12),
                        const ClockInWidget(),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Request Leave'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LeaveRequestScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            UserInfoCard(user: user),
            const SizedBox(height: 16),
            const ClockInWidget(),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Request Leave'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeaveRequestScreen(user: user),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            AnnouncementFeed(announcements: announcements, user: user),
          ],
        );
      },
    );
  }
}
