// news_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_announcement.dart'; // <-- เพิ่ม import นี้ที่ด้านบน
import 'package:campus_life_hub/pages/create_event.dart';
import 'package:intl/intl.dart';

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
      // เพิ่ม FloatingActionButton สำหรับสร้างข่าวสาร
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAnnouncementPage(),
            ),
          );
          // ถ้าสร้างข่าวสารสำเร็จ ให้ refresh หน้านี้
          if (result == true && context.mounted) {
            // Trigger refresh ใน NewsCardList
            // คุณอาจต้องใช้ callback หรือ state management
          }
        },
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'สร้างข่าวสาร',
          style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class NewsCardList extends StatefulWidget {
  final int? currentUserId;
  
  const NewsCardList({super.key, this.currentUserId});

  @override
  State<NewsCardList> createState() => _NewsCardListState();
}

class _NewsCardListState extends State<NewsCardList> with TickerProviderStateMixin {
  String selectedCategory = 'ทั้งหมด';
  List<Map<String, dynamic>> announcements = [];
  List<Event> events = [];
  List<int> bookmarkedAnnouncementIds = [];
  bool isLoading = true;
  late AnimationController _animationController;
  Set<int> expandedCards = {}; // เพิ่มตัวแปรนี้เพื่อเก็บ state ของการขยาย

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
      
      // ดึงข้อมูล events
      List<Event> evs = [];
      if (widget.currentUserId != null) {
        try {
          evs = await fetchEvents();
        } catch (e) {
          print('Error fetching events: $e');
        }
      }
      
      // ดึง bookmarks (ใช้ JWT token)
      List<int> bookmarks = [];
      try {
        bookmarks = await fetchBookmarks();
      } catch (e) {
        print('Error fetching bookmarks: $e');
      }

      if (mounted) {
        setState(() {
          announcements = anns;
          events = evs;
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

  Future<List<Event>> fetchEvents() async {
    if (widget.currentUserId == null) return [];
    
    final response = await http.get(
      Uri.parse('$backendUrl/events/?user_id=${widget.currentUserId}')
        .replace(host: '10.0.2.2', port: 8000),
    );
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Event.fromJson(e)).toList();
    }
    
    throw Exception('Failed to load events: ${response.statusCode}');
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

  Future<void> deleteAnnouncement(int announcementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$backendUrl/announcements/$announcementId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        // Remove from local list
        setState(() {
          announcements.removeWhere((a) => a['id'] == announcementId);
          bookmarkedAnnouncementIds.remove(announcementId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบข่าวสารเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete announcement: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting announcement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถลบข่าวสารได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteEvent(Event event) async {
    if (event.id == null || widget.currentUserId == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/events/${event.id}?user_id=${widget.currentUserId}'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          events.removeWhere((e) => e.id == event.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบกิจกรรมเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถลบกิจกรรมได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(int announcementId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'คุณต้องการลบข่าวสาร "$title" หรือไม่?',
            style: GoogleFonts.kanit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.kanit(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteAnnouncement(announcementId);
              },
              child: Text(
                'ลบ',
                style: GoogleFonts.kanit(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteEventConfirmDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'คุณต้องการลบกิจกรรม "${event.title}" หรือไม่?',
            style: GoogleFonts.kanit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.kanit(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteEvent(event);
              },
              child: Text(
                'ลบ',
                style: GoogleFonts.kanit(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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

    final categories = ['ทั้งหมด', 'บันทึกไว้', 'กิจกรรม', ...announcements.map((e) => e['category'] as String).toSet()];
    
    List<dynamic> filtered = [];
    if (selectedCategory == 'ทั้งหมด') {
      filtered = [...announcements, ...events];
    } else if (selectedCategory == 'บันทึกไว้') {
      filtered = announcements.where((a) => bookmarkedAnnouncementIds.contains(a['id'])).toList();
    } else if (selectedCategory == 'กิจกรรม') {
      filtered = events;
    } else {
      filtered = announcements.where((a) => a['category'] == selectedCategory).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      DateTime dateA;
      DateTime dateB;
      
      if (a is Event) {
        dateA = a.start;
      } else {
        dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
      }
      
      if (b is Event) {
        dateB = b.start;
      } else {
        dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
      }
      
      return dateB.compareTo(dateA);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // ลด padding จาก 20 เป็น 8
      child: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(12), // ลด padding จาก 16 เป็น 12
            margin: const EdgeInsets.symmetric(horizontal: 4), // เพิ่ม margin เล็กน้อย
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // ลด radius จาก 20 เป็น 16
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08), // ลด opacity
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
          const SizedBox(height: 16), // ลดจาก 20 เป็น 16
          
          // Combined Cards
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
                          'ไม่มีข้อมูลในหมวดหมู่นี้',
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
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100, // เพิ่ม padding ด้านล่าง
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - _animationController.value)),
                              child: Opacity(
                                opacity: _animationController.value,
                                child: item is Event
                                    ? _buildEventCard(item)
                                    : _buildNewsCard(
                                        item,
                                        item['id'] as int,
                                        bookmarkedAnnouncementIds.contains(item['id']),
                                        _getCategoryColor(item['category'] ?? ''),
                                      ),
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
    final bool isOwner = widget.currentUserId != null && 
                        doc['created_by_id'] != null && 
                        doc['created_by_id'] == widget.currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4), // ลด margin และเพิ่มซ้าย-ขวา
      width: double.infinity, // บังคับให้กว้างเต็มที่
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ลด radius จาก 16 เป็น 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // ลด opacity
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.08), // ลด opacity
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          key: PageStorageKey(docId),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: Colors.grey.shade600,
          collapsedIconColor: Colors.grey.shade400,
          initiallyExpanded: false, // เพิ่มบรรทัดนี้เพื่อให้เริ่มต้นแบบ collapsed
          maintainState: true, // เพิ่มเพื่อรักษา state
          onExpansionChanged: (bool expanded) {
            setState(() {
              if (expanded) {
                expandedCards.add(docId);
              } else {
                expandedCards.remove(docId);
              }
            });
          },
          title: Container(
            padding: const EdgeInsets.all(16), // ลด padding จาก 20 เป็น 16
            width: double.infinity, // บังคับให้กว้างเต็มที่
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(doc['category'] ?? ''),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Owner Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc['title'] ?? '',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'ของคุณ',
                                style: GoogleFonts.kanit(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Category and Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              doc['category'] ?? '',
                              style: GoogleFonts.kanit(
                                fontSize: 11,
                                color: categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 4,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(doc['created_at']?.toString() ?? ''),
                            style: GoogleFonts.kanit(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Author
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doc['created_by']?['name'] ?? doc['source'] ?? 'ไม่ระบุ',
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            // Detail Content
            if (doc['detail'] != null && doc['detail'].toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  doc['detail'] ?? '',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit and Delete buttons for owner
                if (isOwner)
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'แก้ไข',
                        color: Colors.blue.shade600,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateAnnouncementPage(
                                announcementId: docId,
                                initialData: {
                                  'title': doc['title'] ?? '',
                                  'detail': doc['detail'] ?? '',
                                  'category': doc['category'] ?? '',
                                  'source': doc['source'] ?? '',
                                },
                              ),
                            ),
                          );
                          if (result == true) {
                            loadData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'ลบ',
                        color: Colors.red.shade600,
                        onPressed: () => _showDeleteConfirmDialog(docId, doc['title'] ?? ''),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                
                // Bookmark button
                _buildActionButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border_outlined,
                  label: isSaved ? 'บันทึกแล้ว' : 'บันทึก',
                  color: isSaved ? Colors.orange.shade600 : Colors.grey.shade600,
                  onPressed: () => toggleBookmark(docId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final now = DateTime.now();
    final isUpcoming = event.start.isAfter(now);
    final isPast = event.end.isBefore(now);
    
    Color cardColor;
    String statusText;
    
    if (isPast) {
      cardColor = Colors.grey;
      statusText = 'จบแล้ว';
    } else if (isUpcoming) {
      cardColor = Colors.orange;
      statusText = 'กำลังจะมาถึง';
    } else {
      cardColor = Colors.green;
      statusText = 'กำลังดำเนินการ';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4), // ลด margin และเพิ่มซ้าย-ขวา
      width: double.infinity, // บังคับให้กว้างเต็มที่
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ลด radius จาก 16 เป็น 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // ลด opacity
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.08), // ลด opacity
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: Colors.grey.shade600,
          collapsedIconColor: Colors.grey.shade400,
          initiallyExpanded: false, // เพิ่มบรรทัดนี้
          maintainState: true, // เพิ่มเพื่อรักษา state
          title: Container(
            padding: const EdgeInsets.all(16), // ลด padding จาก 20 เป็น 16
            width: double.infinity, // บังคับให้กว้างเต็มที่
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Type Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cardColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'กิจกรรม',
                              style: GoogleFonts.kanit(
                                fontSize: 10,
                                color: cardColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Status and Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.kanit(
                                fontSize: 11,
                                color: cardColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 4,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(event.start.toString()),
                            style: GoogleFonts.kanit(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('HH:mm').format(event.start)} - ${DateFormat('HH:mm').format(event.end)}',
                            style: GoogleFonts.kanit(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            // Event Details
            if (event.description != null && event.description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.description!,
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'การศึกษา':
        return Icons.school_outlined;
      case 'กิจกรรม':
        return Icons.event_outlined;
      case 'ประกาศ':
        return Icons.campaign_outlined;
      case 'ทุนการศึกษา':
        return Icons.attach_money_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'วันนี้';
      } else if (difference == 1) {
        return 'เมื่อวาน';
      } else if (difference < 7) {
        return '$difference วันที่แล้ว';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = (date.year + 543).toString();
        return '$day/$month/$year';
      }
    } catch (e) {
      return dateString.split('T')[0];
    }
  }
}