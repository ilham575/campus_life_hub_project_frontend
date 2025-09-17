import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TimetableState with ChangeNotifier {
  bool isGrid = false;
  late String selectedWeekday;

  // ✅ ใช้ 10.0.2.2 สำหรับ Android Emulator (แทน localhost)
  final String apiUrl = "http://10.0.2.2:8000/timetable";

  final List<String> days = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์'];
  final List<String> times = [
    '08:00-09:00',
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '13:00-14:00',
    '14:00-15:00',
    '15:00-16:00',
  ];

  final Map<String, String> _subjects = {}; // key = "day|time" → subject
  final Map<String, int> _ids = {};         // key = "day|time" → id

  Map<String, String> get subjects => _subjects;

  TimetableState() {
    selectedWeekday = _getTodayThaiName();
  }

  String _getTodayThaiName() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'จันทร์';
      case DateTime.tuesday:
        return 'อังคาร';
      case DateTime.wednesday:
        return 'พุธ';
      case DateTime.thursday:
        return 'พฤหัสบดี';
      case DateTime.friday:
        return 'ศุกร์';
      default:
        return 'จันทร์';
    }
  }

  /// โหลดข้อมูลจาก API
  Future<void> loadFromApi(String userId) async {
    try {
      final res = await http.get(Uri.parse("$apiUrl/$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _subjects.clear();
        _ids.clear();
        for (var item in data) {
          final key = "${item['day']}|${item['time']}";
          _subjects[key] = item['subject'];
          _ids[key] = item['id'];
        }
        notifyListeners();
      } else {
        debugPrint("โหลดตารางล้มเหลว: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("error loadFromApi: $e");
    }
  }

  /// เพิ่มหรือแก้ไขวิชา
  Future<void> updateSubject(
      String userId, String day, String time, String subject) async {
    final key = '$day|$time';
    final id = _ids[key]; // mapping day|time → id

    if (id != null) {
      // ✅ PUT แก้ไข
      final res = await http.put(
        Uri.parse("$apiUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "day": day,
          "time": time,
          "subject": subject,
        }),
      );

      if (res.statusCode == 200) {
        _subjects[key] = subject;
        notifyListeners();
      } else {
        debugPrint("แก้ไขวิชาล้มเหลว: ${res.statusCode} ${res.body}");
      }
    } else {
      // ✅ POST เพิ่มใหม่
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "day": day,
          "time": time,
          "subject": subject,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) { // 👈 รองรับทั้ง 200 และ 201
        final data = jsonDecode(res.body);
        _subjects[key] = subject;
        _ids[key] = data["id"]; // ✅ เก็บ id ไว้ใช้ตอน update/delete
        notifyListeners();
      } else {
        debugPrint("เพิ่มวิชาล้มเหลว: ${res.statusCode} ${res.body}");
      }
    }
  }

  /// ลบวิชา
  Future<void> removeSubject(int id, String day, String time) async {
    try {
      final res = await http.delete(Uri.parse("$apiUrl/$id"));
      if (res.statusCode == 200) {
        final key = "$day|$time";
        _subjects.remove(key);
        _ids.remove(key);
        notifyListeners();
      } else {
        debugPrint("ลบวิชาล้มเหลว: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("error removeSubject: $e");
    }
  }

  int? getIdFor(String day, String time) {
    return _ids["$day|$time"];
  }

  void toggleView() {
    isGrid = !isGrid;
    selectedWeekday = _getTodayThaiName();
    notifyListeners();
  }

  void setDay(String day) {
    selectedWeekday = day;
    notifyListeners();
  }

  void resetToToday() {
    selectedWeekday = _getTodayThaiName();
    notifyListeners();
  }
}
