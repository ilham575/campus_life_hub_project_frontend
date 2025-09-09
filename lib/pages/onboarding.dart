import 'package:flutter/material.dart';
import 'package:campus_life_hub/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
      "title": "Welcome to Campus Life Hub",
      "desc": "แอปสำหรับชีวิตในมหาวิทยาลัยของคุณ",
    },
    {
      "image": "https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
      "title": "กิจกรรมมากมาย",
      "desc": "ค้นหากิจกรรมและข่าวสารในรั้วมหาวิทยาลัย",
    },
    {
      "image": "https://cdn-icons-png.flaticon.com/512/1077/1077012.png",
      "title": "เริ่มต้นใช้งาน",
      "desc": "สมัครสมาชิกหรือเข้าสู่ระบบเพื่อเริ่มต้น",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(_pages[index]["image"]!, height: 200),
                          const SizedBox(height: 40),
                          Text(
                            _pages[index]["title"]!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _pages[index]["desc"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.deepPurple
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_currentPage == _pages.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('seenOnboarding', true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? "เริ่มต้นใช้งาน"
                          : "ถัดไป",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            // ปุ่มข้ามที่มุมขวาบน
            Positioned(
              top: 16,
              right: 16,
              child: Visibility(
                visible: _currentPage != _pages.length - 1,
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('seenOnboarding', true);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                  child: const Text(
                    "ข้าม",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
