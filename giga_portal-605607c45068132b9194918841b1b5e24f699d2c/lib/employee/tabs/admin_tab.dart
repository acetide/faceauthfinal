import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import '../../services/leave_api_service.dart';
import '../leave_detail_screen.dart';

class AdminTab extends StatefulWidget {
  final void Function(Announcement announcement) onCreate;

  const AdminTab({
    super.key,
    required this.onCreate,
  });

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final List<LeaveRequest> _leaveRequests = [];
  bool _creatingAnnouncement = false;
  bool _loadingLeaves = true;
  String? _leaveError;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    if (!mounted) return;
    setState(() {
      _loadingLeaves = true;
      _leaveError = null;
    });

    try {
      final leaves = await LeaveApiService.getLeaveRequests();
      if (!mounted) return;
      setState(() {
        _leaveRequests
          ..clear()
          ..addAll(leaves);
        _loadingLeaves = false;
      });
      await LeaveService.update(leaves);
    } catch (e) {
      try {
        final stored = await LeaveService.load();
        if (!mounted) return;
        setState(() {
          _leaveRequests
            ..clear()
            ..addAll(stored);
          _loadingLeaves = false;
          _leaveError = 'Offline mode - showing cached data';
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _loadingLeaves = false;
          _leaveError = 'Failed to load leave requests';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    if (!mounted) return;
    setState(() => _imageFile = File(file.path));
  }

  void _openCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Attach Image'),
                  ),
                  const SizedBox(width: 12),
                  if (_imageFile != null)
                    const Text('Image attached', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                    onPressed: _creatingAnnouncement
                        ? null
                        : () async {
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

                      setState(() => _creatingAnnouncement = true);

                      try {
                        final created = await AnnouncementService().createAnnouncement(
                          title: ann.title,
                          description: ann.description,
                          imageFile: _imageFile,
                        );

                        widget.onCreate(created);

                        _titleCtrl.clear();
                        _descCtrl.clear();
                        setState(() => _imageFile = null);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _creatingAnnouncement = false);
                        }
                      }
                    },
                    child: _creatingAnnouncement
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Announcement'),
            onPressed: _openCreateDialog,
          ),
          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Leave Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _loadingLeaves
                ? const Center(child: CircularProgressIndicator())
                : _leaveError != null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_leaveError!),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadLeaves, child: const Text('Retry')),
                        ],
                      ))
                    : _leaveRequests.isEmpty
                        ? const Center(child: Text('No leave requests'))
                        : ListView.builder(
                            itemCount: _leaveRequests.length,
                            itemBuilder: (ctx, i) {
                              final l = _leaveRequests[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text('${l.employeeCode} — ${l.submissionType}'),
                                  subtitle: Text('${l.startDate.toLocal().toIso8601String().split('T').first} → ${l.endDate.toLocal().toIso8601String().split('T').first}\nStatus: ${l.submissionStatus}'),
                                  isThreeLine: true,
                                  onTap: () => _viewLeaveDetails(l),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) => _handleLeaveAction(v, l, i),
                                    itemBuilder: (c) => [
                                      if (l.submissionStatus == 'Pending')
                                        const PopupMenuItem(value: 'accept', child: Text('Accept')),
                                      if (l.submissionStatus == 'Pending')
                                        const PopupMenuItem(value: 'reject', child: Text('Reject')),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _handleLeaveAction(String action, LeaveRequest l, int index) async {
    if (action == 'accept') {
      try {
        final updated = await LeaveApiService.approveLeaveRequest(l.id);
        if (!mounted) return;
        setState(() {
          _leaveRequests[index] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave approved')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')));
      }
      return;
    }

    // reject
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Reason for rejection')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Reject')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')));
    }
  }

  void _viewLeaveDetails(LeaveRequest leave) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LeaveDetailScreen(leave: leave),
      ),
    );
  }
}
