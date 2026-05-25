import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';

class LocalStorageService {
  static const String _key = 'announcements';

  /// SAVE announcements
  static Future<void> save(List<Announcement> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// LOAD announcements
  static Future<List<Announcement>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map<Announcement>((e) => Announcement.fromJson(e)).toList();
    } catch (e) {
      await prefs.remove(_key);
      return [];
    }
  }

  /// CLEAR announcements
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
