import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final nikCtrl = TextEditingController();
  bool loading = false;

  void resetPassword() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => loading = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Password has been reset to your NIK.\nPlease login and change it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your password will be reset to your NIK.',
              style: TextStyle(color: Colors.grey),
            ),
            TextField(
              controller: nikCtrl,
              decoration: const InputDecoration(labelText: 'Enter NIK'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : resetPassword,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('RESET PASSWORD'),
            ),
          ],
        ),
      ),
    );
  }
}
