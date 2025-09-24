import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Schedule {
  int? id;
  String day;
  String startTime;
  String endTime;

  Schedule({this.id, required this.day, required this.startTime, required this.endTime});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json["id"],
      day: json["day"],
      startTime: json["start_time"],
      endTime: json["end_time"],
    );
  }
}

class Subject {
  int id;
  String name;
  List<Schedule> schedules;

  Subject({required this.id, required this.name, required this.schedules});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json["id"],
      name: json["name"],
      schedules: (json["schedules"] as List).map((s) => Schedule.fromJson(s)).toList(),
    );
  }
}

class TimetableState with ChangeNotifier {
  bool isGrid = false;
  late String selectedWeekday;

  // ✅ base url ไม่ใส่ / ปิดท้าย
  final String apiUrl = "http://10.0.2.2:8000/subjects";

  final List<String> days = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์'];

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

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

  // ✅ รับ userId แล้วส่งไปที่ path
  Future<void> loadFromApi(String userId) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse("$apiUrl/$userId"), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _subjects = (data as List).map((s) => Subject.fromJson(s)).toList();
        notifyListeners();
      } else {
        debugPrint("โหลดตารางล้มเหลว: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("error loadFromApi: $e");
    }
  }

  Future<void> addSubject(String name, List<Schedule> schedules, String userId) async {
    final headers = await _getHeaders();
    final body = {
      "name": name,
      "schedules": schedules
          .map((s) => {
                "user_id": userId,
                "day": s.day,
                "start_time": s.startTime,
                "end_time": s.endTime,
              })
          .toList()
    };

    final res = await http.post(Uri.parse("$apiUrl/"), headers: headers, body: jsonEncode(body));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _subjects.add(Subject.fromJson(data));
      notifyListeners();
    } else {
      debugPrint("เพิ่มวิชาล้มเหลว: ${res.statusCode} ${res.body}");
    }
  }

  Future<void> removeSubject(int subjectId) async {
    final headers = await _getHeaders();
    final res = await http.delete(Uri.parse("$apiUrl/$subjectId"), headers: headers);

    if (res.statusCode == 200) {
      _subjects.removeWhere((s) => s.id == subjectId);
      notifyListeners();
    } else {
      debugPrint("ลบวิชาล้มเหลว: ${res.statusCode} ${res.body}");
    }
  }

  Future<void> updateSubject(int subjectId, String name, List<Schedule> schedules, String userId) async {
    final headers = await _getHeaders();
    final body = {
      "name": name,
      "schedules": schedules
          .map((s) => {
                "user_id": userId,
                "day": s.day,
                "start_time": s.startTime,
                "end_time": s.endTime,
              })
          .toList()
    };

    final res = await http.put(
      Uri.parse("$apiUrl/$subjectId"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        _subjects[index] = Subject.fromJson(data);
        notifyListeners();
      }
    } else {
      debugPrint("แก้ไขวิชาล้มเหลว: ${res.statusCode} ${res.body}");
    }
  }

  Future<void> removeSchedule(int scheduleId) async {
    final headers = await _getHeaders();
    final res = await http.delete(Uri.parse("$apiUrl/schedule/$scheduleId"), headers: headers);

    if (res.statusCode == 200) {
      // เอาออกจาก state
      for (var subj in _subjects) {
        subj.schedules.removeWhere((s) => s.id == scheduleId);
      }
      notifyListeners();
    } else {
      debugPrint("ลบ schedule ล้มเหลว: ${res.statusCode} ${res.body}");
    }
  }

  Future<void> loadUserTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id"); // ✅ เก็บ user_id ไว้ตอน login
      if (userId == null) return;

      final headers = await _getHeaders();
      final res = await http.get(Uri.parse("$apiUrl/$userId"), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _subjects = (data as List).map((s) => Subject.fromJson(s)).toList();
        notifyListeners();
      } else {
        debugPrint("โหลดตารางล้มเหลว: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("error loadFromApi: $e");
    }
  }

  Future<void> removeScheduleAndCheck(int scheduleId) async {
    final headers = await _getHeaders();
    final res = await http.delete(Uri.parse("$apiUrl/schedule/$scheduleId"), headers: headers);

    if (res.statusCode == 200) {
      Subject? foundSubject;

      // 1. ลบ schedule ใน state
      for (var subj in _subjects) {
        subj.schedules.removeWhere((s) => s.id == scheduleId);
        if (subj.schedules.isEmpty) {
          foundSubject = subj; // เจอ subject ที่ไม่เหลือ schedule แล้ว
        }
      }

      // 2. ถ้า subject ไม่มี schedule เหลือ → ลบออกเลย
      if (foundSubject != null) {
        await removeSubject(foundSubject.id);
      }

      notifyListeners();
    } else {
      debugPrint("ลบ schedule ล้มเหลว: ${res.statusCode} ${res.body}");
    }
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
