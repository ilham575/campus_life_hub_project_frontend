// lib/widgets/main_navbar.dart
import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.deepPurple.shade50, // เปลี่ยนสีพื้นหลัง
      selectedItemColor: Colors.deepPurple, // สีไอคอน/label ที่เลือก
      unselectedItemColor: Colors.grey, // สีไอคอน/label ที่ไม่ได้เลือก
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'ตารางเรียน'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'แผนที่'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
      ],
    );
  }
}
