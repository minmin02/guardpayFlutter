import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  String? accessToken;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await storage.read(key: 'accessToken');
    setState(() {
      accessToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 상단 검색창 + 알림/설정 아이콘 (이미지 버전)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽 메뉴 아이콘
                  const Icon(Icons.menu, color: Colors.black87, size: 26),
                  const SizedBox(width: 10),

                  // 검색창 아이콘 + 입력창
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해주세요.',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // 🔔 알림 아이콘 (이미지)
                  Image.asset(
                    'assets/images/alram_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),

                  // ⚙️ 설정 아이콘 (이미지)
                  Image.asset(
                    'assets/images/setting_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),


            // 🔹 상단 노란 배너
            Container(
              width: 358,
              height: 85,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8C6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/character_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 25),
                  const Expanded(
                    child: Text(
                      '안전 송금, 퀴즈로 배우자!\n퀴즈 풀고 포인트를 모아요!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 아래 카드 3개
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCard(
                      title: '역량 진단 시작하기',
                      subtitle: '나의 금융 이해도를 측정해보세요!',
                      imagePath: 'assets/images/check_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/abilityTest');
                      },
                    ),
                    _buildCard(
                      title: '금융 퀴즈 도전',
                      subtitle: '맞히면 포인트가 쌓여요!',
                      imagePath: 'assets/images/quiz_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/quiz');
                      },
                    ),
                    _buildCard(
                      title: '보이스피싱 예방 영상',
                      subtitle: '보이스피싱 수법과 대처법을\n영상으로 확인하세요!',
                      imagePath: 'assets/images/video_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/video');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 하단 네비게이션바 (이미지 라벨 포함된 아이콘만)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomImageOnlyIcon(
                    imagePath: 'assets/images/home_icon.png',
                    isActive: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _BottomImageOnlyIcon(
                    imagePath: 'assets/images/AI_icon.png',
                    isActive: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _BottomImageOnlyIcon(
                    imagePath: 'assets/images/shop_icon.png',
                    isActive: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  _BottomImageOnlyIcon(
                    imagePath: 'assets/images/money_icon.png',
                    isActive: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  _BottomImageOnlyIcon(
                    imagePath: 'assets/images/map_icon.png',
                    isActive: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 카드 위젯 (오른쪽 하단 이미지)
  Widget _buildCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 358,
        height: 137,
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 20,
              child: SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 하단 네비게이션 이미지 아이콘 (텍스트 라벨 제거)
class _BottomImageOnlyIcon extends StatelessWidget {
  final String imagePath;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomImageOnlyIcon({
    required this.imagePath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: 45,
        height: 45,
        color: isActive ? null : Colors.black54, // 비활성 시 약간 어둡게 처리
      ),
    );
  }
}
