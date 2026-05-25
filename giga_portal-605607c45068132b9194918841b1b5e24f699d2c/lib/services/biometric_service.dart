import 'package:flutter/foundation.dart';

class BiometricService {
  Future<bool> authenticate() async {
    if (kIsWeb) {
      return true;
    }

    return true;
  }
}
