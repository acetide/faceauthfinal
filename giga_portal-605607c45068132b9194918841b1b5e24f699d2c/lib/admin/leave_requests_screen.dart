import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class LeaveRequestsScreen extends StatelessWidget {
  const LeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: FutureBuilder<Response>(
        future: ApiService().dio.get('/users?page=2'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final response = snapshot.data!;
          final List users = response.data['data'];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                title: Text('${user['first_name']} ${user['last_name']}'),
                subtitle: Text(user['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
