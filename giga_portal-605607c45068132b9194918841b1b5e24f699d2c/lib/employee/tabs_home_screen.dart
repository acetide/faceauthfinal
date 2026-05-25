import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../services/local_storage_service.dart';
import '../services/token_storage.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../services/announcement_service.dart';
import '../utils/dio_error_handler.dart';
import 'tabs/home_tab.dart';
import 'tabs/pengajuan_tab.dart';

class TabsHomeScreen extends StatefulWidget {
  final User user;

  const TabsHomeScreen({super.key, required this.user});

  @override
  State<TabsHomeScreen> createState() => _TabsHomeScreenState();
}

class _TabsHomeScreenState extends State<TabsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() => _isLoading = true);
      final apiAnnouncements = await AnnouncementService().getAnnouncements();

      if (!mounted) return;

      final cached = await LocalStorageService.load();

      final Map<String, Announcement> cachedMap = {
        for (var c in cached) c.id: c,
      };

      final merged = <Announcement>[];

      for (var a in apiAnnouncements) {
        final cachedA = cachedMap[a.id];
        if (cachedA != null) {
          final mergedAnn = Announcement(
            id: a.id,
            title: a.title,
            description: a.description,
            imagePath: a.imagePath ?? cachedA.imagePath,
            imageFileName: a.imageFileName,
            imageContentType: a.imageContentType,
            comments: a.comments,
          );
          merged.add(mergedAnn);
          cachedMap.remove(a.id);
        } else {
          merged.add(a);
        }
      }

      if (cachedMap.isNotEmpty) {
        merged.insertAll(0, cachedMap.values);
      }

      setState(() {
        _announcements
          ..clear()
          ..addAll(merged);
        _isLoading = false;
      });

      await LocalStorageService.save(_announcements);
    } catch (e) {
      final cached = await LocalStorageService.load();
      if (!mounted) return;

      final errorText = e is DioException
          ? handleDioError(e)
          : e.toString().replaceAll('Exception:', '').trim();

      setState(() {
        _announcements
          ..clear()
          ..addAll(cached);
        _error = errorText;
        _isLoading = false;
      });
    }
  }

  Future<void> _addAnnouncement(Announcement announcement) async {
    try {
      final created = await AnnouncementService().createAnnouncement(
        title: announcement.title,
        description: announcement.description,
        imageFile: null, // Not used in this context
      );

      if (!mounted) return;

      setState(() {
        _announcements.insert(0, created);
      });

      await LocalStorageService.save(_announcements);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Image.asset(
                'assets/images/giga_sena-removebg-preview.png',
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Giga Group',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Employee Management System',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _logout();
                },
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Pengajuan'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAnnouncements,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : HomeTab(user: user, announcements: _announcements),
                PengajuanTab(user: user),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
}
