import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TimetableState with ChangeNotifier {
  bool isGrid = false;
  late String selectedWeekday;

  final String apiUrl = "http://10.0.2.2:8000/timetable/";

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

  final Map<String, String> _subjects = {};
  final Map<String, int> _ids = {};

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

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  /// โหลดข้อมูลจาก API (แนบ token)
  Future<void> loadFromApi() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse(apiUrl), headers: headers);
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

  /// เพิ่มหรือแก้ไขวิชา (แนบ token)
  Future<void> updateSubject(String day, String time, String subject) async {
    final key = '$day|$time';
    final id = _ids[key];
    final headers = await _getHeaders();

    if (id != null) {
      final res = await http.put(
        Uri.parse("$apiUrl$id"),
        headers: headers,
        body: jsonEncode({
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
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode({
          "day": day,
          "time": time,
          "subject": subject,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _subjects[key] = subject;
        _ids[key] = data["id"];
        notifyListeners();
      } else {
        debugPrint("เพิ่มวิชาล้มเหลว: ${res.statusCode} ${res.body}");
      }
    }
  }

  /// ลบวิชา (แนบ token)
  Future<void> removeSubject(int id, String day, String time) async {
  try {
    final headers = await _getHeaders();
    final res = await http.delete(
      Uri.parse("$apiUrl$id"), // <-- ไม่มี / ซ้ำ
      headers: headers,
    );
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