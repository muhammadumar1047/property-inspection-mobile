import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import '../models/inspection_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _inspectionsKey = 'cached_inspections';
  static const _pendingReportsKey = 'pending_reports';

  static Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    print('saveSession: token saved = $token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    print("my user data is: ${userJson}::${_userKey}");
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> saveInspections(List<InspectionModel> inspections) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(inspections.map((e) => e.toJson()).toList());
    await prefs.setString(_inspectionsKey, encoded);
  }

  static Future<List<InspectionModel>> getCachedInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inspectionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => InspectionModel.fromJson(e)).toList();
  }

  static Future<void> savePendingReport(Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingReportsKey);
    final list = raw != null ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    list.add(report);
    await prefs.setString(_pendingReportsKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingReportsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> removePendingReport(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingReportsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (index < list.length) list.removeAt(index);
    await prefs.setString(_pendingReportsKey, jsonEncode(list));
  }
}
