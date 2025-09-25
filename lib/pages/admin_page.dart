import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Admin Panel', style: TextStyle(fontSize: 24)),
            // เพิ่ม widget สำหรับจัดการ user, ประกาศ ฯลฯ
          ],
        ),
      ),
    );
  }
}