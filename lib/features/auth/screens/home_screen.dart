import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'chat_screen.dart';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart';
import 'package:guardpayfront/features/auth/screens/mypage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = AppStorage.storage;
  final ApiService _api = ApiService();
  int _selectedIndex = 0;

  String? accessToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await storage.read(key: 'accessToken');

    if (token != null) {
      setState(() => accessToken = token);
    } else {
      print("🚨 HomeScreen: 저장된 토큰이 없습니다. 로그인 화면으로 이동합니다.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔹 상단 검색창 + 아이콘들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Colors.black87, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해주세요.',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Image.asset('assets/images/alert_icon.png',
                      width: 26, height: 26),
                  const SizedBox(width: 12),
                  // ✅ 톱니바퀴 아이콘을 GestureDetector로 감싸서 마이페이지로 이동
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/mypage');
                    },
                    child: Image.asset('assets/images/settings_icon.png',
                        width: 26, height: 26),
                  ),
                ],
              ),
            ),

            // 🔹 상단 배너
            Container(
              width: double.infinity,
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8C6),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 15.0),
                    child: Image.asset(
                      'assets/images/main_icon.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(width: 25),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 13.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '안전 송금, 퀴즈로 배우자!\n퀴즈 풀고 포인트를 모아요!',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 11),

            // 🔹 카드 3개
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCard(
                      title: '역량 진단 시작하기',
                      imagePath: 'assets/images/checkBox_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/assessment');
                      },
                    ),
                    _buildCard(
                      title: '금융 퀴즈 도전',
                      imagePath: 'assets/images/quiz_icon2.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/quizCategory');
                      },
                    ),
                    _buildCard(
                      title: '보이스피싱 예방 영상',
                      imagePath: 'assets/images/youtube_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/video');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 0),
    );
  }

  Widget _buildCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 347,
        height: 140,
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(37),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              top: 27,
              child: Image.asset(imagePath, width: 50, height: 50),
            ),
            Positioned(
              left: 35,
              top: 35,
              child: SizedBox(
                width: 350 - (16 * 2),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23.5,
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