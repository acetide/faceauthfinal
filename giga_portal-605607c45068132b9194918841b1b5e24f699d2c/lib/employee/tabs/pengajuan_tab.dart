import 'package:flutter/material.dart';
import '../../models/leave_request.dart';
import '../../models/user_model.dart';
import '../../services/leave_api_service.dart';
import '../../services/leave_service.dart';
import '../leave_detail_screen.dart';

class PengajuanTab extends StatefulWidget {
  final User user;

  const PengajuanTab({super.key, required this.user});

  @override
  State<PengajuanTab> createState() => _PengajuanTabState();
}

class _PengajuanTabState extends State<PengajuanTab> {
  bool _isLoading = true;
  String? _error;
  List<LeaveRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leaves = await LeaveApiService.getLeaveRequests();
      final userRequests = leaves
          .where((leave) => leave.employeeCode == widget.user.kodeNik)
          .toList();
      userRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

      if (!mounted) return;
      setState(() {
        _requests = userRequests;
        _isLoading = false;
      });

      await LeaveService.update(leaves);
    } catch (e) {
      final cached = await LeaveService.load();
      final userRequests = cached
          .where((leave) => leave.employeeCode == widget.user.kodeNik)
          .toList();
      userRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

      if (!mounted) return;
      setState(() {
        _requests = userRequests;
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
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

  Widget _buildRequestCard(BuildContext context, LeaveRequest request) {
    final statusColor = _statusColor(request.submissionStatus);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(request.submissionType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Status: ${request.submissionStatus}'),
            Text('Period: ${request.startDate.toLocal().toIso8601String().split('T').first} - ${request.endDate.toLocal().toIso8601String().split('T').first}'),
            Text('Submitted: ${request.submissionDate.toLocal().toIso8601String().split('T').first}'),
          ],
        ),
        trailing: Chip(
          label: Text(request.submissionStatus),
          backgroundColor: statusColor.withAlpha(41),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaveDetailScreen(leave: request),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No pending Leave Requests',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You do not have any leave applications waiting for approval at the moment.',
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text('Error loading requests: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadRequests,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final latestRequest = _requests.first;
    final pastRequests = _requests.length > 1 ? _requests.sublist(1) : <LeaveRequest>[];

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Latest Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRequestCard(context, latestRequest),
          if (pastRequests.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Past Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...pastRequests.map((request) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(context, request),
                )),
          ],
        ],
      ),
    );
  }
}
