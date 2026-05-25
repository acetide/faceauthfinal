import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/employee_profile_service.dart';

class AdminEmployeeProfileManager extends StatefulWidget {
  final User admin;

  const AdminEmployeeProfileManager({super.key, required this.admin});

  @override
  State<AdminEmployeeProfileManager> createState() => _AdminEmployeeProfileManagerState();
}

class _AdminEmployeeProfileManagerState extends State<AdminEmployeeProfileManager> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _employeeSearchCtrl = TextEditingController();
  File? _selectedImage;
  String? _selectedEmployeeKodeNik;
  String? _selectedEmployeeName;
  bool _uploading = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _message = null;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error picking image: $e';
        _messageIsError = true;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null || _selectedEmployeeKodeNik == null) {
      setState(() {
        _message = 'Please select both an image and an employee';
        _messageIsError = true;
      });
      return;
    }

    setState(() => _uploading = true);

    try {
      await EmployeeProfileService().uploadEmployeeProfilePicture(
        employeeKodeNik: _selectedEmployeeKodeNik!,
        imageFile: _selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        _uploading = false;
        _message = 'Profile picture uploaded successfully for $_selectedEmployeeName';
        _messageIsError = false;
        _selectedImage = null;
        _selectedEmployeeKodeNik = null;
        _selectedEmployeeName = null;
        _employeeSearchCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message!), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _uploading = false;
        _message = 'Error: $e';
        _messageIsError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message!), backgroundColor: Colors.red),
      );
    }
  }

  void _selectEmployee(String kodeNik, String name) {
    setState(() {
      _selectedEmployeeKodeNik = kodeNik;
      _selectedEmployeeName = name;
      _employeeSearchCtrl.text = name;
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _employeeSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Employee Profile Picture',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Image preview
          if (_selectedImage != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Image'),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 150,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to select image', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Employee search field
          TextField(
            controller: _employeeSearchCtrl,
            readOnly: true,
            onTap: () => _showEmployeeSelector(context),
            decoration: InputDecoration(
              labelText: 'Select Employee',
              hintText: _selectedEmployeeName ?? 'Tap to select employee',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
          ),

          const SizedBox(height: 16),

          // Message
          if (_message != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageIsError ? Colors.red.shade50 : Colors.green.shade50,
                border: Border.all(color: _messageIsError ? Colors.red : Colors.green),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _messageIsError ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading || _selectedImage == null || _selectedEmployeeKodeNik == null
                  ? null
                  : _uploadProfilePicture,
              child: _uploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload Profile Picture'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeSelector(BuildContext context) {
    // Mock employee list - in production, this would fetch from API or database
    // For now, we'll show a simple dialog to enter employee KodeNik
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Employee'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Enter Employee KodeNik',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _selectEmployee(value, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
