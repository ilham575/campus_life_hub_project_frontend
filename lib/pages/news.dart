// news_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            // แสดงรายการข่าวในหน้า NewsPage ด้วย
            const Expanded(child: NewsCardList()),
          ],
        ),
      ),
    );
  }
}

// เพิ่ม Widget สำหรับแสดงข่าว
class NewsCardList extends StatefulWidget {
  const NewsCardList({super.key});

  @override
  State<NewsCardList> createState() => _NewsCardListState();
}

class _NewsCardListState extends State<NewsCardList> {
  String selectedCategory = 'ทั้งหมด';
  final Set<String> savedIds = {};
  final Map<String, bool> expandedMap = {}; // เพิ่ม map สำหรับสถานะเปิด/ปิด

  // ลบ setState ออกจาก _updateCategories
  List<String> _getCategories(List<DocumentSnapshot> docs) {
    final cats = docs.map((e) => e['category'] as String).toSet().toList();
    cats.sort();
    return ['ทั้งหมด', ...cats];
  }

  Future<void> _toggleSave(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('announcement').doc(id);

    setState(() {
      if (savedIds.contains(id)) {
        savedIds.remove(id);
        // remove uid from saved array in Firestore
        docRef.update({
          'saved': FieldValue.arrayRemove([uid])
        });
      } else {
        savedIds.add(id);
        // add uid to saved array in Firestore
        docRef.update({
          'saved': FieldValue.arrayUnion([uid])
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcement').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่พบข่าวสาร'));
        }

        final docs = snapshot.data!.docs;
        final categories = _getCategories(docs);

        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid;

        final filteredDocs = selectedCategory == 'ทั้งหมด'
            ? docs
            : docs.where((doc) => doc['category'] == selectedCategory).toList();

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
            ...filteredDocs.map((doc) {
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final List<dynamic>? savedList = data['saved'] is List ? data['saved'] as List<dynamic> : null;
              final isSaved = savedList != null && uid != null ? savedList.contains(uid) : savedIds.contains(docId);

              // กำหนดสถานะเปิด/ปิด
              final isExpanded = expandedMap[docId] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  key: PageStorageKey(docId), // ใช้ key เพื่อคง state
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      expandedMap[docId] = expanded;
                    });
                  },
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
                          onPressed: () => _toggleSave(docId),
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
      },
    );
  }
}