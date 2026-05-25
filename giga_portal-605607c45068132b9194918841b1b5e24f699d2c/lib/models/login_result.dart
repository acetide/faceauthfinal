import 'user_model.dart';

class LoginResult {
  final String token;
  final User user;

  LoginResult({
    required this.token,
    required this.user,
  });
}
