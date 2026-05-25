import 'package:flutter/foundation.dart';

class LocationService {
  Future<bool> isWithinOffice() async {
    if (kIsWeb) {
      return true;
    }

    return true;
  }
}
