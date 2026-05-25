import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../employee/tabs_home_screen.dart';
import '../admin/admin_panel.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final (String token, User user) = await authService.login(
        userName: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      /// JABATAN
      final isAdmin = user.jabatan == 'C5';
      final destination = isAdmin ? AdminPanel(user: user) : TabsHomeScreen(user: user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('DioException:', '')
            .trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset(
                'assets/images/giga_sena-removebg-preview.png',
                width: 220,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              /// USERNAME
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username / NIK / Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              /// PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              /// ERROR MESSAGE
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
