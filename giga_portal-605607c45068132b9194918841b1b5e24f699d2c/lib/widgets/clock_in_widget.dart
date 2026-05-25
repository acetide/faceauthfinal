import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/face_verification_service.dart';
import '../session/user_session.dart';

class ClockInWidget extends StatefulWidget {
  const ClockInWidget({super.key});

  @override
  State<ClockInWidget> createState() => _ClockInWidgetState();
}

class _ClockInWidgetState extends State<ClockInWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isChecking = false;
  String? _result;

  static const double officeLat = -6.2486473;
  static const double officeLon = 106.8436725;
  static const double allowedDistance = 15; // meters

  Future<void> _clockIn() async {
    setState(() {
      _isChecking = true;
      _result = null;
    });

    if (currentUser == null) {
      setState(() {
        _result = 'User session is unavailable. Please log in again.';
        _isChecking = false;
      });
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) {
      setState(() {
        _result = 'Face capture was cancelled. Please try again.';
        _isChecking = false;
      });
      return;
    }

    try {
      final verification = await FaceVerificationService().verifyFaceAgainstEmployee(
        employeeKodeNik: currentUser!.kodeNik,
        probeImage: File(image.path),
      );

      if (!verification.success) {
        setState(() {
          _result = 'Face verification failed: ${verification.message}';
          _isChecking = false;
        });
        return;
      }

      if (!verification.verified) {
        setState(() {
          _result = '❌ Face did not match the registered reference. ${verification.message}';
          _isChecking = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _result = 'Face verification error: $e';
        _isChecking = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _result = 'Location permission denied';
        _isChecking = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = Geolocator.distanceBetween(
      officeLat,
      officeLon,
      position.latitude,
      position.longitude,
    );

    if (distance <= allowedDistance) {
      final now = DateTime.now();
      final formatted = DateFormat('yyyy-MM-dd – HH:mm:ss').format(now);

      setState(() {
        _result = '✅ Clocked in successfully\n$formatted';
      });
    } else {
      setState(() {
        _result =
            '❌ You are too far from the office\n(${distance.toStringAsFixed(2)} m away)';
      });
    }

    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _clockIn,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Clock In'),
            ),
            const SizedBox(height: 12),
            if (_isChecking) const CircularProgressIndicator(),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_result!),
              ),
          ],
        ),
      ),
    );
  }
}
