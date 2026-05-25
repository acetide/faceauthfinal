import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_request.dart';

class LeaveService {
  static const _key = 'leave_requests';

  static Future<void> save(List<LeaveRequest> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((l) => l.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<LeaveRequest>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return [];

    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map<LeaveRequest>((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      await prefs.remove(_key);
      return [];
    }
  }

  static Future<void> add(LeaveRequest req) async {
    final list = await load();
    list.insert(0, req);
    await save(list);
  }

  static Future<void> update(List<LeaveRequest> list) async {
    await save(list);
  }
}
