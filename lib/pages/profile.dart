import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: ValueListenableBuilder<Key>(
        valueListenable: _fbKey,
        builder: (context, key, _) {
          return FutureBuilder<Map<String, dynamic>?>(
            key: key,
            future: _fetchProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
              }
              final data = snapshot.data!;
              return Center(
                child: UserInfoCard(
                  name: data['name'] ?? '',
                  studentId: data['student_id'] ?? '',
                  faculty: data['faculty'] ?? '',
                  year: data['year']?.toString() ?? '',
                  email: userEmail,
                  onEdit: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
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
                            Navigator.pop(context, true); // ส่งค่า true กลับไป
                          },
                        );
                      },
                    );
                    if (result == true) {
                      // เปลี่ยน key เพื่อ trigger rebuild
                      _fbKey.value = UniqueKey();
                    }
                  },
                ),
              );
            },
          );
        },
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'รหัสนักศึกษา: $studentId',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              'คณะ: $faculty',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              'ชั้นปี: $year',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('แก้ไขข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 183, 162, 219),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'แก้ไขข้อมูลโปรไฟล์',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'ชื่อ'),
          ),
          TextField(
            controller: idController,
            decoration: const InputDecoration(labelText: 'รหัสนักศึกษา'),
          ),
          TextField(
            controller: facultyController,
            decoration: const InputDecoration(labelText: 'คณะ'),
          ),
          TextField(
            controller: yearController,
            decoration: const InputDecoration(labelText: 'ชั้นปี'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
