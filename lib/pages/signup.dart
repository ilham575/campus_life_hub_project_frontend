import 'package:campus_life_hub/pages/login.dart';
import 'package:campus_life_hub/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatelessWidget {
  Signup({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signin(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Register Account',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _nameField(),
              const SizedBox(height: 20),
              _studentIdField(),
              const SizedBox(height: 20),
              _facultyField(),
              const SizedBox(height: 20),
              _yearField(),
              const SizedBox(height: 20),
              _emailAddress(),
              const SizedBox(height: 20),
              _password(),
              const SizedBox(height: 50),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailAddress() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'อีเมล',
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _password() {
    return ValueListenableBuilder<bool>(
      valueListenable: _obscurePassword,
      builder: (context, obscure, _) {
        return TextField(
          controller: _passwordController,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'รหัสผ่าน',
            filled: true,
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                _obscurePassword.value = !obscure;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _signup(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 2, 2, 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        // ตรวจสอบข้อมูลจำเป็น
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณากรอกอีเมลและรหัสผ่าน'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // แสดง loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          bool success = await AuthService().signup(
            username: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text.isNotEmpty ? _nameController.text : null,
            studentId: _studentIdController.text.isNotEmpty ? _studentIdController.text : null,
            faculty: _facultyController.text.isNotEmpty ? _facultyController.text : null,
            year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
          );

          // ปิด loading dialog
          if (context.mounted) Navigator.pop(context);

          if (success) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xffF7F7F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.black12, width: 2),
                  ),
                  title: Text(
                    'สมัครสำเร็จ',
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  content: Text(
                    'ข้อมูลของคุณถูกบันทึกแล้ว\nไปหน้า Login เพื่อเข้าสู่ระบบ',
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text(
                        'ไปหน้า Login',
                        style: GoogleFonts.raleway(
                          textStyle: const TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่สามารถสมัครได้ กรุณาตรวจสอบข้อมูลและลองใหม่'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          // ปิด loading dialog
          if (context.mounted) Navigator.pop(context);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: const Text(
        "Sign Up",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _signin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Already Have Account? ",
              style: TextStyle(
                color: Color(0xff6A6A6A),
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Log In",
              style: const TextStyle(
                color: Color(0xff1A1D1E),
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'ชื่อ',
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _studentIdField() {
    return TextField(
      controller: _studentIdController,
      decoration: InputDecoration(
        labelText: 'รหัสนักศึกษา',
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _facultyField() {
    return TextField(
      controller: _facultyController,
      decoration: InputDecoration(
        labelText: 'คณะ',
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _yearField() {
    return TextField(
      controller: _yearController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'ชั้นปี',
        filled: true,
        fillColor: const Color(0xffF7F7F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
