// news_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

const String backendUrl = 'http://192.168.110.81:8000';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'ข่าวสาร',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Expanded(child: NewsCardList()),
          ],
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

class _NewsCardListState extends State<NewsCardList> {
  String selectedCategory = 'ทั้งหมด';
  List<Map<String, dynamic>> announcements = [];
  List<int> bookmarkedAnnouncementIds = [];
  bool isLoading = true;

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
      
      // ถ้า backend ยังไม่มี user นี้ ให้ใช้ empty list
      List<int> bookmarks = [];
      try {
        bookmarks = await fetchBookmarks(userId);
      } catch (e) {
        print('No bookmarks found for user, using empty list');
      }

      setState(() {
        announcements = anns;
        bookmarkedAnnouncementIds = bookmarks;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
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
      print('Fetching bookmarks for user: $userId'); // Debug log
      final response = await http.get(Uri.parse('$backendUrl/bookmarks/?user_id=$userId'));
      print('Bookmark response status: ${response.statusCode}'); // Debug log
      print('Bookmark response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<int>((b) => b['announcement_id'] as int).toList();
      }
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error fetching bookmarks: $e'); // Debug log
      throw Exception('Failed to load bookmarks: $e');
    }
  }

  Future<void> addBookmark(String userId, int announcementId) async {
    await http.post(
      Uri.parse('$backendUrl/bookmarks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'announcement_id': announcementId}), // ลบ int.parse() ออก
    );
  }

  Future<void> removeBookmark(String userId, int announcementId) async {
    // สมมติ backend มี endpoint /bookmarks/?user_id=xxx&announcement_id=yyy
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final categories = ['ทั้งหมด', ...announcements.map((e) => e['category'] as String).toSet()];
    final filtered = selectedCategory == 'ทั้งหมด'
        ? announcements
        : announcements.where((a) => a['category'] == selectedCategory).toList();

    return Column(
      children: [
        Row(
          children: [
            const Text('หมวดหมู่:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value ?? 'ทั้งหมด';
                });
              },
            ),
          ],
        ),
        ...filtered.map((doc) {
          final docId = doc['id'] as int;
          final isSaved = bookmarkedAnnouncementIds.contains(docId);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              key: PageStorageKey(docId),
              leading: const Icon(Icons.campaign, color: Colors.deepPurple),
              title: Row(
                children: [
                  Expanded(
                    child: Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doc['category'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              subtitle: Text(doc['source'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(doc['detail'] ?? ''),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () => toggleBookmark(docId),
                      tooltip: isSaved ? 'ยกเลิกบันทึก' : 'บันทึกประกาศ',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}