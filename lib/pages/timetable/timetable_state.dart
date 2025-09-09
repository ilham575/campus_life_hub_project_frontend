import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimetableState with ChangeNotifier {
  bool isGrid = false;
  late String selectedWeekday;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

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

  Map<String, String> get subjects => _subjects;

  TimetableState() {
    selectedWeekday = _getTodayThaiName();
    // ฟังการเปลี่ยนแปลงสถานะการล็อกอินของผู้ใช้
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _subjects.clear(); // ล้างข้อมูลเก่าทันที
      if (user != null) {
        _loadFromFirestore(); // โหลดข้อมูลของผู้ใช้ใหม่
      }
      notifyListeners(); // แจ้งให้ UI อัปเดต
    });
  }

  String _getTodayThaiName() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE', 'th');
    final weekday = formatter.format(now);
    if (weekday.contains('จันทร์')) return 'จันทร์';
    if (weekday.contains('อังคาร')) return 'อังคาร';
    if (weekday.contains('พุธ')) return 'พุธ';
    if (weekday.contains('พฤหัส')) return 'พฤหัสบดี';
    if (weekday.contains('ศุกร์')) return 'ศุกร์';
    return 'จันทร์';
  }

   Future<void> _loadFromFirestore() async {
    if (_userId == null) return;
    
    final doc = await _db.collection('timetable').doc(_userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _subjects.clear();
      data.forEach((key, value) {
        _subjects[key] = value.toString();
      });
      notifyListeners();
    }
    
  }
  
  Future<void> _saveToFirestore() async {
    if (_userId == null) return;

    await _db.collection('timetable').doc(_userId).set(_subjects);
    
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

  void updateSubject(String day, String time, String subject) {
    _subjects['$day|$time'] = subject;
    notifyListeners();
    _saveToFirestore();
  }

  void removeSubject(String day, String time) {
    _subjects.remove('$day|$time');
    notifyListeners();
    _saveToFirestore();
  }

  void resetToToday() {
    selectedWeekday = _getTodayThaiName();
    notifyListeners();
  }

}
