// news_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _animationController.dispose(); // ไม่ต้องใช้ ? แล้ว
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final userId = user.uid;
      final anns = await fetchAnnouncements();
      
      List<int> bookmarks = [];
      try {
        bookmarks = await fetchBookmarks(userId);
      } catch (e) {
        print('No bookmarks found for user, using empty list');
      }

      if (mounted) {
        setState(() {
          announcements = anns;
          bookmarkedAnnouncementIds = bookmarks;
          isLoading = false;
        });
        _animationController.forward(); // ไม่ต้องใช้ ? แล้ว
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final response = await http.get(Uri.parse('$backendUrl/announcements/'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load announcements');
  }

  Future<List<int>> fetchBookmarks(String userId) async {
    try {
      print('Fetching bookmarks for user: $userId');
      final response = await http.get(Uri.parse('$backendUrl/bookmarks/?user_id=$userId'));
      print('Bookmark response status: ${response.statusCode}');
      print('Bookmark response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<int>((b) => b['announcement_id'] as int).toList();
      }
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error fetching bookmarks: $e');
      throw Exception('Failed to load bookmarks: $e');
    }
  }

  Future<void> addBookmark(String userId, int announcementId) async {
    await http.post(
      Uri.parse('$backendUrl/bookmarks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'announcement_id': announcementId}),
    );
  }

  Future<void> removeBookmark(String userId, int announcementId) async {
    final response = await http.get(Uri.parse('$backendUrl/bookmarks/?user_id=$userId&announcement_id=$announcementId'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final bookmarkId = data[0]['id'];
        await http.delete(Uri.parse('$backendUrl/bookmarks/$bookmarkId'));
      }
    }
  }

  Future<void> toggleBookmark(int announcementId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    if (bookmarkedAnnouncementIds.contains(announcementId)) {
      await removeBookmark(userId, announcementId);
    } else {
      await addBookmark(userId, announcementId);
    }
    await loadData();
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

    final categories = ['ทั้งหมด', ...announcements.map((e) => e['category'] as String).toSet()];
    final filtered = selectedCategory == 'ทั้งหมด'
        ? announcements
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
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final docId = doc['id'] as int;
                      final isSaved = bookmarkedAnnouncementIds.contains(docId);
                      final categoryColor = _getCategoryColor(doc['category'] ?? '');

                      // ไม่ต้องตรวจสอบ null แล้ว
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