import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../services/leave_api_service.dart';
import '../services/token_storage.dart';
import '../services/api_service.dart';
import '../services/announcement_service.dart';
import '../services/local_storage_service.dart';
import '../screens/login_screen.dart';
import '../employee/leave_detail_screen.dart';
import '../employee/announcement_detail_screen.dart';
import 'employee_profile_manager.dart';

class AdminPanel extends StatefulWidget {
  final User user;

  const AdminPanel({super.key, required this.user});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Announcements
  final List<Announcement> _announcements = [];
  bool _loadingAnnouncements = true;
  String? _announcementError;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Leave Requests
  final List<LeaveRequest> _leaveRequests = [];
  bool _loadingLeaves = true;
  String? _leaveError;

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl = ApiService().dio.options.baseUrl;
    return '$baseUrl$imagePath';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnnouncements();
    _loadLeaves();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() {
      _loadingAnnouncements = true;
      _announcementError = null;
    });

    try {
      final apiAnnouncements = await AnnouncementService().getAnnouncements();
      if (!mounted) return;

      setState(() {
        _announcements
          ..clear()
          ..addAll(apiAnnouncements);
        _loadingAnnouncements = false;
      });

      await LocalStorageService.save(_announcements);
    } catch (e) {
      try {
        final stored = await LocalStorageService.load();
        if (!mounted) return;

        setState(() {
          _announcements
            ..clear()
            ..addAll(stored);
          _loadingAnnouncements = false;
          _announcementError = 'Offline mode - showing cached data';
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _loadingAnnouncements = false;
          _announcementError = e2.toString();
        });
      }
    }
  }

  Future<void> _addAnnouncement(Announcement announcement) async {
    try {
      final created = await AnnouncementService().createAnnouncement(
        title: announcement.title,
        description: announcement.description,
        imageFile: _imageFile,
      );

      if (!mounted) return;

      setState(() {
        _announcements.insert(0, created);
      });

      await LocalStorageService.save(_announcements);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _loadLeaves() async {
    if (!mounted) return;
    setState(() {
      _loadingLeaves = true;
      _leaveError = null;
    });

    try {
      // Try to fetch from backend first
      final leaves = await LeaveApiService.getLeaveRequests();
      if (!mounted) return;
      setState(() {
        _leaveRequests
          ..clear()
          ..addAll(leaves);
        _loadingLeaves = false;
      });
      // Update local storage
      await LeaveService.update(leaves);
    } catch (e) {
      final errMsg = e.toString();
      // debugPrint('[AdminPanel._loadLeaves] fetch error: $errMsg');

      // Fallback to local storage on error
      try {
        final stored = await LeaveService.load();
        if (!mounted) return;
        setState(() {
          _leaveRequests
            ..clear()
            ..addAll(stored);
          _loadingLeaves = false;
          _leaveError = 'Offline mode - showing cached data\nReason: $errMsg';
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _loadingLeaves = false;
          _leaveError = e2.toString();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final imageFile = File(file.path);
      setState(() => _imageFile = imageFile);
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Title (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 12),
              if (_imageFile != null)
                Column(
                  children: [
                    Image.file(_imageFile!, height: 150),
                    const SizedBox(height: 8),
                  ],
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleCtrl.clear();
              _descCtrl.clear();
              setState(() => _imageFile = null);
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final title = _titleCtrl.text.trim();
              final desc = _descCtrl.text.trim();
              if (title.isEmpty && desc.isEmpty && _imageFile == null) return;

              final ann = Announcement(
                id: DateTime.now().toIso8601String(),
                title: title.isEmpty ? 'Untitled' : title,
                description: desc.isEmpty ? '-' : desc,
                imagePath: null,
                comments: [],
              );

              _addAnnouncement(ann);
              _titleCtrl.clear();
              _descCtrl.clear();
              setState(() => _imageFile = null);

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement created successfully'),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.amber.shade700;
    }
  }

  void _handleLeaveAction(String action, LeaveRequest l, int index) async {
    if (action == 'accept') {
      try {
        final updated = await LeaveApiService.approveLeaveRequest(l.id);
        if (!mounted) return;
        setState(() {
          _leaveRequests[index] = updated;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Leave approved')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
      return;
    }

    // reject
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (res == null || res.isEmpty) return;

    try {
      final updated = await LeaveApiService.rejectLeaveRequest(l.id, res);
      if (!mounted) return;
      setState(() {
        _leaveRequests[index] = updated;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
        ),
      );
    }
  }

  void _viewLeaveDetails(LeaveRequest leave) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => LeaveDetailScreen(leave: leave)),
    );
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
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Leave Requests'),
            Tab(text: 'Employee Profiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Announcements Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    'assets/images/giga_sena-removebg-preview.png',
                    width: 180,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Announcement'),
                  onPressed: _openCreateDialog,
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Announcements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loadingAnnouncements
                      ? const Center(child: CircularProgressIndicator())
                      : _announcementError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_announcementError'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadAnnouncements,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _announcements.isEmpty
                      ? const Center(child: Text('No announcements yet'))
                      : ListView.builder(
                          itemCount: _announcements.length,
                          itemBuilder: (ctx, i) {
                            final a = _announcements[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (a.imagePath != null)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 150,
                                      child: Image.network(
                                        _buildImageUrl(a.imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ListTile(
                                    title: Text(a.title),
                                    subtitle: Text(a.description),
                                    leading: const Icon(Icons.announcement),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnnouncementDetailScreen(
                                            announcement: a,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Leave Requests Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Leave Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loadingLeaves
                      ? const Center(child: CircularProgressIndicator())
                      : _leaveError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_leaveError!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadLeaves,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _leaveRequests.isEmpty
                      ? const Center(child: Text('No leave requests'))
                      : ListView(
                          children: [
                            // Pending Requests
                            if (_leaveRequests.any((l) => l.submissionStatus == 'Pending')) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Pending Requests',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._leaveRequests
                                  .where((l) => l.submissionStatus == 'Pending')
                                  .map((l) => Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: _getStatusColor(l.submissionStatus), width: 2),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            '${l.employeeCode} — ${l.submissionType}',
                                          ),
                                          subtitle: Text(
                                            '${l.startDate.toLocal().toIso8601String().split('T').first} → ${l.endDate.toLocal().toIso8601String().split('T').first}\nStatus: ${l.submissionStatus}',
                                          ),
                                          isThreeLine: true,
                                          onTap: () => _viewLeaveDetails(l),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (v) => _handleLeaveAction(
                                                v, l, _leaveRequests.indexOf(l)),
                                            itemBuilder: (c) => [
                                              const PopupMenuItem(
                                                value: 'accept',
                                                child: Text('Accept'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'reject',
                                                child: Text('Reject'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                            ],
                            // Processed Requests (Accepted/Rejected)
                            if (_leaveRequests.any((l) => l.submissionStatus != 'Pending')) ...[
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Processed Requests',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._leaveRequests
                                  .where((l) => l.submissionStatus != 'Pending')
                                  .map((l) => Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: _getStatusColor(l.submissionStatus), width: 2),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            '${l.employeeCode} — ${l.submissionType}',
                                          ),
                                          subtitle: Text(
                                            '${l.startDate.toLocal().toIso8601String().split('T').first} → ${l.endDate.toLocal().toIso8601String().split('T').first}\nStatus: ${l.submissionStatus}',
                                          ),
                                          isThreeLine: true,
                                          onTap: () => _viewLeaveDetails(l),
                                        ),
                                      )),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Employee Profiles Tab
          AdminEmployeeProfileManager(admin: widget.user),
        ],
      ),
    );
  }
}
