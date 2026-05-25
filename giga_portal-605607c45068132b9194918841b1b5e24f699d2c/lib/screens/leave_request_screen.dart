import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/leave_api_service.dart';
import '../services/leave_service.dart';
import '../models/leave_request.dart';
import '../models/user_model.dart';

class LeaveRequestScreen extends StatefulWidget {
  final User user;

  const LeaveRequestScreen({super.key, required this.user});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Sick';
  final TextEditingController _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  File? _attachmentFile;
  bool _isSubmitting = false;

  static const int _maxAttachmentBytes = 5 * 1024 * 1024;

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      withData: false, // ✅ IMPORTANT
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;

    if (picked.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected file')),
      );
      return;
    }

    final file = File(picked.path!);

    final size = await file.length();
    if (size > _maxAttachmentBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment must be 5MB or less')),
      );
      return;
    }

    setState(() {
      _attachmentFile = file;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (dt != null) setState(() => _startDate = dt);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (dt != null) setState(() => _endDate = dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select start and end date')),
      );
      return;
    }

    final duration = _endDate!.difference(_startDate!).inDays + 1;

    setState(() => _isSubmitting = true);

    try {
      await LeaveApiService.createLeaveRequest(
        widget.user.kodeNik,
        duration,
        _descCtrl.text.trim(),
        _startDate!,
        _endDate!,
        _type,
        _attachmentFile, // ✅ FILE
      );

      // Optional local save
      await LeaveService.add(
        LeaveRequest(
          employeeCode: widget.user.kodeNik,
          durationDays: duration,
          description: _descCtrl.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          submissionType: _type,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                  DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'Sick'),
                decoration: const InputDecoration(labelText: 'Leave Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartDate,
                      child: Text(
                        _startDate == null
                            ? 'Start Date'
                            : _startDate!.toIso8601String().split('T').first,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndDate,
                      child: Text(
                        _endDate == null
                            ? 'End Date'
                            : _endDate!.toIso8601String().split('T').first,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach File'),
                  ),
                  const SizedBox(width: 12),
                  if (_attachmentFile != null)
                    const Text('Attached', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
