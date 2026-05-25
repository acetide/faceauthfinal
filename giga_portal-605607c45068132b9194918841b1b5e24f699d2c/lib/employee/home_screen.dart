import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import 'tabs/announcements_tab.dart';
import '../services/local_storage_service.dart';
import '../services/token_storage.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../widgets/user_info_card.dart';
import '../widgets/clock_in_widget.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Announcement> announcements = [];
  String _activeView = 'employee';

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    final stored = await LocalStorageService.load();
    if (!mounted) return;

    setState(() {
      announcements
        ..clear()
        ..addAll(stored);
    });
  }

  Future<void> _logout() async {
    ApiService().clearToken();
    await TokenStorage.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.apartment, size: 36, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Giga Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Employee Management System', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text('View as:', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Employee'),
                      selected: _activeView == 'employee',
                      onSelected: (_) => setState(() => _activeView = 'employee'),
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Admin'),
                      selected: _activeView == 'admin',
                      onSelected: (_) => setState(() => _activeView = 'admin'),
                      selectedColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Logout',
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AnnouncementsTab(announcements: announcements, user: widget.user),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 360,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UserInfoCard(user: widget.user),
                            const SizedBox(height: 12),
                            const ClockInWidget(),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Need Time Off?', style: Theme.of(context).textTheme.titleSmall),
                                        const SizedBox(height: 6),
                                        Text('Submit a leave request for approval', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.calendar_today),
                                      label: const Text('Request'),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        AnnouncementsTab(announcements: announcements, user: widget.user),
                        const SizedBox(height: 12),
                        UserInfoCard(user: widget.user),
                        const SizedBox(height: 12),
                        const ClockInWidget(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
