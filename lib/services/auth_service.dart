import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/home.dart';
import '../pages/login.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8000"; // สำหรับ Emulator

  Future<bool> signup({
    required String username,
    required String password,
    required String firebaseUid,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "firebase_uid": firebaseUid,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> signin({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": username,
        "password": password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["access_token"]);
      return true;
    }
    return false;
  }

  Future<void> signout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token"); // ลบ token

    // พากลับไปหน้า Login
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }
}

