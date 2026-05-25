import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/face_verification_service.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingReference = true;
  bool _isRegistering = false;
  Uint8List? _referenceImage;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadFaceReference();
  }

  Future<void> _loadFaceReference() async {
    setState(() {
      _isLoadingReference = true;
      _message = null;
    });

    try {
      final imageBytes = await FaceVerificationService().getEmployeeFaceReference(widget.user.kodeNik);
      if (!mounted) return;
      setState(() {
        _referenceImage = imageBytes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _referenceImage = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReference = false;
      });
    }
  }

  Future<void> _registerFace() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo == null) {
      setState(() {
        _message = 'Face capture cancelled.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isRegistering = true;
      _message = null;
    });

    try {
      final message = await FaceVerificationService().storeFaceReference(
        employeeKodeNik: widget.user.kodeNik,
        imageFile: File(photo.path),
      );

      if (!mounted) return;
      setState(() {
        _message = message;
        _messageIsError = false;
      });
      await _loadFaceReference();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to register face: $e';
        _messageIsError = true;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFaceSection(),
            const SizedBox(height: 24),
            info('Name', widget.user.name),
            info('NIK', widget.user.kodeNik),
            info('Email', widget.user.email),
            info('Jabatan', widget.user.jabatan),
            info('Bagian', widget.user.bagian),
            info('Cabang', widget.user.namaCabang),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Face Reference',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoadingReference)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_referenceImage != null)
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _referenceImage!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text('No registered face reference yet'),
            ),
          ),
        const SizedBox(height: 16),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _message!,
              style: TextStyle(
                color: _messageIsError ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRegistering ? null : _registerFace,
            icon: const Icon(Icons.face_retouching_natural),
            label: _isRegistering
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Register Face'),
          ),
        ),
      ],
    );
  }

  Widget info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
