import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String backendUrl = 'http://10.0.2.2:8000';

class CreateAnnouncementPage extends StatefulWidget {
  final int? announcementId;
  final Map<String, String>? initialData;
  
  const CreateAnnouncementPage({
    super.key,
    this.announcementId,
    this.initialData,
  });

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _sourceController = TextEditingController();
  
  String _selectedCategory = 'การศึกษา';
  bool _isLoading = false;
  bool get _isEditing => widget.announcementId != null;

  final List<String> _categories = [
    'การศึกษา',
    'กิจกรรม', 
    'ประกาศ',
    'ทุนการศึกษา',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _detailController.text = widget.initialData!['detail'] ?? '';
      _sourceController.text = widget.initialData!['source'] ?? '';
      _selectedCategory = widget.initialData!['category'] ?? 'การศึกษา';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('กรุณาเข้าสู่ระบบใหม่');
      }

      final url = _isEditing 
          ? '$backendUrl/announcements/${widget.announcementId}'
          : '$backendUrl/announcements/';
      
      final response = _isEditing
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'title': _titleController.text,
                'category': _selectedCategory,
                'source': _sourceController.text.isEmpty ? null : _sourceController.text,
                'detail': _detailController.text.isEmpty ? null : _detailController.text,
              }),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'title': _titleController.text,
                'category': _selectedCategory,
                'source': _sourceController.text.isEmpty ? null : _sourceController.text,
                'detail': _detailController.text.isEmpty ? null : _detailController.text,
              }),
            );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'แก้ไขข่าวสารสำเร็จ!' : 'สร้างข่าวสารสำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 401) {
        throw Exception('กรุณาเข้าสู่ระบบใหม่');
      } else {
        throw Exception('เกิดข้อผิดพลาด: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'ไม่สามารถแก้ไขข่าวสารได้: $e' 
                : 'ไม่สามารถสร้างข่าวสารได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'แก้ไขข่าวสาร' : 'สร้างข่าวสาร',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Field
                          _buildSectionTitle('หัวข้อข่าวสาร'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _titleController,
                            hintText: 'กรอกหัวข้อข่าวสาร',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกหัวข้อข่าวสาร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Category Field
                          _buildSectionTitle('หมวดหมู่'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: GoogleFonts.kanit(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Source Field
                          _buildSectionTitle('แหล่งที่มา (ไม่บังคับ)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _sourceController,
                            hintText: 'เช่น คณะวิศวกรรมศาสตร์, สำนักงานอธิการบดี',
                          ),
                          const SizedBox(height: 20),

                          // Detail Field
                          _buildSectionTitle('รายละเอียด (ไม่บังคับ)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _detailController,
                            hintText: 'กรอกรายละเอียดข่าวสาร',
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditing ? 'บันทึกการแก้ไข' : 'สร้างข่าวสาร',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.kanit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.kanit(color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.kanit(),
      ),
    );
  }
}