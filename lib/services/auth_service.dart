import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/home.dart';
import '../pages/login.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8000";

  Future<bool> signup({
    required String username,
    required String password,
    String? name,
    String? studentId,
    String? faculty,
    int? year,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    // Debug: แสดงข้อมูลที่จะส่ง
    // print('Sending signup data:');
    // print('Username: $username');
    // print('Name: $name');
    // print('Student ID: $studentId');
    // print('Faculty: $faculty');
    // print('Year: $year');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "name": name,
        "student_id": studentId,
        "faculty": faculty,
        "year": year,
      }),
    );

    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Signup successful');
      return true;
    } else {
      print('Signup failed: ${response.statusCode} - ${response.body}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> signin({
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
      
      // เก็บ token และ user data
      await prefs.setString("token", data["access_token"]);
      await prefs.setString("user_data", jsonEncode(data["user"]));
      
      print('Login successful for user: ${data["user"]["username"]}');
      return data["user"];
    } else {
      print('Login failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    
    if (token == null) {
      print('No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        // อัพเดต user data ใน SharedPreferences
        await prefs.setString("user_data", jsonEncode(userData));
        print('Current user: ${userData["username"]}');
        return userData;
      } else if (response.statusCode == 401) {
        // Token หมดอายุ ให้ logout
        await signout();
        return null;
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    
    return null;
  }

  Future<bool> updateProfile({
    String? name,
    String? studentId,
    String? faculty,
    int? year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/auth/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "student_id": studentId,
          "faculty": faculty,
          "year": year,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        // อัพเดต user data ใน SharedPreferences
        await prefs.setString("user_data", jsonEncode(userData));
        print('Profile updated successfully');
        return true;
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
    
    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return token != null && token.isNotEmpty;
  }

  Future<void> signout([BuildContext? context]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_data");
    
    print('User signed out');

    if (context != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }
}

