import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/user_profile_screen.dart';
import 'dart:typed_data';
import '../services/employee_profile_service.dart';

class UserInfoCard extends StatelessWidget {
  final User user;

  const UserInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(user.jabatan, style: Theme.of(context).textTheme.bodySmall),
                    Text(user.namaCabang, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (user.kodeNik.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFE8EAF6),
        child: const Icon(Icons.person, size: 32),
      );
    }

    return FutureBuilder<Uint8List>(
      future: EmployeeProfileService().getEmployeeProfilePicture(user.kodeNik),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8EAF6),
            child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8EAF6),
            child: const Icon(Icons.person, size: 32),
          );
        }

        return CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE8EAF6),
          child: ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
