// news_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String backendUrl = 'http://10.0.2.2:8000';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.purple.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.newspaper,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'ข่าวสารและประกาศ',
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
              const Expanded(child: NewsCardList()),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCardList extends StatefulWidget {
  const NewsCardList({super.key});

  @override
  State<NewsCardList> createState() => _NewsCardListState();
}

class _NewsCardListState extends State<NewsCardList> with TickerProviderStateMixin {
  String selectedCategory = 'ทั้งหมด';
  List<Map<String, dynamic>> announcements = [];
  List<int> bookmarkedAnnouncementIds = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ดึง JWT Token จาก SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // สร้าง headers สำหรับ API calls
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {"Content-Type": "application/json"};
    
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    
    return headers;
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // ดึงข้อมูลประกาศ
      final anns = await fetchAnnouncements();
      
      // ดึง bookmarks (ใช้ JWT token)
      List<int> bookmarks = [];
      try {
        bookmarks = await fetchBookmarks();
      } catch (e) {
        print('Error fetching bookmarks: $e');
        // ไม่ต้อง throw error เพราะ bookmarks ไม่จำเป็น
      }

      if (mounted) {
        setState(() {
          announcements = anns;
          bookmarkedAnnouncementIds = bookmarks;
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // แสดง error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final response = await http.get(Uri.parse('$backendUrl/announcements/'));
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    
    throw Exception('Failed to load announcements: ${response.statusCode}');
  }

  Future<List<int>> fetchBookmarks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$backendUrl/bookmarks/'),
        headers: headers,
      );
      
      print('Bookmarks response status: ${response.statusCode}');
      print('Bookmarks response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<int>((b) => b['announcement_id'] as int).toList();
      } else if (response.statusCode == 401) {
        throw Exception('กรุณาเข้าสู่ระบบใหม่');
      }
      
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error fetching bookmarks: $e');
      throw Exception('Failed to load bookmarks: $e');
    }
  }

  Future<void> addBookmark(int announcementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$backendUrl/bookmarks/'),
        headers: headers,
        body: json.encode({'announcement_id': announcementId}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to add bookmark: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding bookmark: $e');
      throw Exception('ไม่สามารถบันทึกได้: $e');
    }
  }

  Future<void> removeBookmark(int announcementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$backendUrl/bookmarks/by-announcement/$announcementId'),
        headers: headers,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to remove bookmark: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing bookmark: $e');
      throw Exception('ไม่สามารถยกเลิกการบันทึกได้: $e');
    }
  }

  Future<void> toggleBookmark(int announcementId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return; // ไม่แสดง message
      }

      // เก็บสถานะเดิมไว้ก่อน
      final wasBookmarked = bookmarkedAnnouncementIds.contains(announcementId);
      
      // อัพเดต UI ทันที (Optimistic Update)
      setState(() {
        if (wasBookmarked) {
          bookmarkedAnnouncementIds.remove(announcementId);
        } else {
          bookmarkedAnnouncementIds.add(announcementId);
        }
      });

      // ทำงาน API ใน background
      if (wasBookmarked) {
        await removeBookmark(announcementId);
      } else {
        await addBookmark(announcementId);
      }
      
    } catch (e) {
      // กรณี error ให้ revert UI กลับเป็นสถานะเดิม
      setState(() {
        if (bookmarkedAnnouncementIds.contains(announcementId)) {
          bookmarkedAnnouncementIds.remove(announcementId);
        } else {
          bookmarkedAnnouncementIds.add(announcementId);
        }
      });
      
      print('Bookmark error: $e');
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'การศึกษา':
        return Colors.blue;
      case 'กิจกรรม':
        return Colors.green;
      case 'ประกาศ':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลดข่าวสาร...',
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

    final categories = ['ทั้งหมด', 'บันทึกไว้', ...announcements.map((e) => e['category'] as String).toSet()];
    final filtered = selectedCategory == 'ทั้งหมด'
        ? announcements
        : selectedCategory == 'บันทึกไว้'
            ? announcements.where((a) => bookmarkedAnnouncementIds.contains(a['id'])).toList()
            : announcements.where((a) => a['category'] == selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  'หมวดหมู่:',
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: GoogleFonts.kanit(),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value ?? 'ทั้งหมด';
                        });
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: loadData,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.grey.shade600,
                  ),
                  tooltip: 'รีเฟรชข้อมูล',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // News Cards
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีข่าวสารในหมวดหมู่นี้',
                          style: GoogleFonts.kanit(
                            textStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('รีเฟรชข้อมูล'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final docId = doc['id'] as int;
                        final isSaved = bookmarkedAnnouncementIds.contains(docId);
                        final categoryColor = _getCategoryColor(doc['category'] ?? '');

                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - _animationController.value)),
                              child: Opacity(
                                opacity: _animationController.value,
                                child: _buildNewsCard(doc, docId, isSaved, categoryColor),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> doc, int docId, bool isSaved, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          key: PageStorageKey(docId),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.all(20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.campaign,
              color: categoryColor,
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doc['title'] ?? '',
                      style: GoogleFonts.kanit(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      doc['category'] ?? '',
                      style: GoogleFonts.kanit(
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.source,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doc['source'] ?? '',
                    style: GoogleFonts.kanit(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (doc['created_at'] != null)
                    Text(
                      doc['created_at'].toString().split('T')[0],
                      style: GoogleFonts.kanit(
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                doc['detail'] ?? '',
                style: GoogleFonts.kanit(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSaved ? Colors.orange.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.orange.shade700 : Colors.grey.shade600,
                    ),
                    onPressed: () => toggleBookmark(docId),
                    tooltip: isSaved ? 'ยกเลิกบันทึก' : 'บันทึกประกาศ',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}