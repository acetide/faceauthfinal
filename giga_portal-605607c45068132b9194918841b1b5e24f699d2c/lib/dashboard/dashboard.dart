import 'package:flutter/material.dart';
import '../session/user_session.dart';
import '../login_page/change_password.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jabatan: ${user.jabatan}'),
            Text('Bagian: ${user.bagian}'),
            Text('Cabang: ${user.namaCabang}'),
            Text('Koperasi: ${user.namaKoperasi}'),
          ],
        ),
      ),
    );
  }
}
