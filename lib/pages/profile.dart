import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static final ValueNotifier<Key> _fbKey = ValueNotifier(Key('profile'));

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<Key>(
            valueListenable: _fbKey,
            builder: (context, key, _) {
              return FutureBuilder<Map<String, dynamic>?>(
                key: key,
                future: _fetchProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'กำลังโหลดข้อมูล...',
                            style: GoogleFonts.kanit(
                              textStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่พบข้อมูลผู้ใช้',
                            style: GoogleFonts.kanit(
                              textStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple.shade600, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'โปรไฟล์ของฉัน',
                                style: GoogleFonts.kanit(
                                  textStyle: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        UserInfoCard(
                          name: data['name'] ?? '',
                          studentId: data['student_id'] ?? '',
                          faculty: data['faculty'] ?? '',
                          year: data['year']?.toString() ?? '',
                          email: userEmail,
                          onEdit: () async {
                            final result = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) {
                                final nameController = TextEditingController(text: data['name'] ?? '');
                                final idController = TextEditingController(text: data['student_id'] ?? '');
                                final facultyController = TextEditingController(text: data['faculty'] ?? '');
                                final yearController = TextEditingController(text: data['year']?.toString() ?? '');
                                return EditProfileForm(
                                  nameController: nameController,
                                  idController: idController,
                                  facultyController: facultyController,
                                  yearController: yearController,
                                  onSave: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({
                                            'name': nameController.text,
                                            'student_id': idController.text,
                                            'faculty': facultyController.text,
                                            'year': int.tryParse(yearController.text) ?? yearController.text,
                                          });
                                    }
                                    Navigator.pop(context, true);
                                  },
                                );
                              },
                            );
                            if (result == true) {
                              _fbKey.value = UniqueKey();
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String name;
  final String studentId;
  final String faculty;
  final String year;
  final String email;
  final VoidCallback onEdit;

  const UserInfoCard({
    super.key,
    required this.name,
    required this.studentId,
    required this.faculty,
    required this.year,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Name
            Text(
              name.isNotEmpty ? name : 'ไม่ระบุชื่อ',
              style: GoogleFonts.kanit(
                textStyle: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Info Cards
            _buildInfoCard(
              icon: Icons.badge_outlined,
              title: 'รหัสนักศึกษา',
              value: studentId.isNotEmpty ? studentId : 'ไม่ระบุ',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.school_outlined,
              title: 'คณะ',
              value: faculty.isNotEmpty ? faculty : 'ไม่ระบุ',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.grade_outlined,
              title: 'ชั้นปี',
              value: year.isNotEmpty ? 'ปีที่ $year' : 'ไม่ระบุ',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'อีเมล',
              value: email,
              color: Colors.purple,
            ),
            
            const SizedBox(height: 32),
            
            // Edit Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                label: Text(
                  'แก้ไขข้อมูล',
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kanit(
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController facultyController;
  final TextEditingController yearController;
  final VoidCallback onSave;

  const EditProfileForm({
    super.key,
    required this.nameController,
    required this.idController,
    required this.facultyController,
    required this.yearController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'แก้ไขข้อมูลโปรไฟล์',
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Form Fields
            _buildTextField(
              controller: nameController,
              label: 'ชื่อ-นามสกุล',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: idController,
              label: 'รหัสนักศึกษา',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: facultyController,
              label: 'คณะ',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: yearController,
              label: 'ชั้นปี',
              icon: Icons.grade_outlined,
            ),
            const SizedBox(height: 32),
            
            // Save Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  'บันทึกข้อมูล',
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.kanit(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.kanit(
            textStyle: TextStyle(color: Colors.grey.shade600),
          ),
          prefixIcon: Icon(icon, color: Colors.purple.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
