import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'chat_screen.dart';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = AppStorage.storage;
  final ApiService _api = ApiService();

  String? accessToken;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await storage.read(key: 'accessToken');

    if (token != null) {
      setState(() {
        accessToken = token;
      });
    } else {
      print("🚨 HomeScreen: 저장된 토큰이 없습니다. 로그인 화면으로 이동합니다.");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔹 상단 검색창 + 알림/설정 아이콘 (팀원 디자인 적용)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽 메뉴 아이콘
                  const Icon(Icons.menu, color: Colors.black87, size: 26),
                  const SizedBox(width: 10),

                  // 검색창 (팀원 디자인: prefixIcon 사용)
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해주세요.',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  // 🔔 알림 아이콘 (팀원 이미지명: alert_icon.png)
                  Image.asset(
                    'assets/images/alert_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),

                  // ⚙️ 설정 아이콘 (팀원 이미지명: settings_icon.png)
                  Image.asset(
                    'assets/images/settings_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // 🔹 상단 노란 배너 (팀원 디자인 적용)
            Container(
              width: 412,
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8C6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 15.0),
                    child: Image.asset(
                      'assets/images/main_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 25),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 13.0, bottom: 11.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '안전 송금, 퀴즈로 배우자!\n퀴즈 풀고 포인트를 모아요!',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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

            // 🔹 아래 카드 3개 (기존 로직 유지, 디자인만 변경)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCard(
                      title: '역량 진단 시작하기',
                      imagePath: 'assets/images/checkBox_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/abilityTest');
                      },
                    ),
                    _buildCard(
                      title: '금융 퀴즈 도전',
                      imagePath: 'assets/images/quiz_icon2.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/quiz');
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

            // 🔹 하단 네비게이션바 (기존 로직 유지)
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
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(api: _api),
                        ),
                      );
                    },
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

  // 🔹 카드 위젯 (팀원 디자인 전면 적용)
  Widget _buildCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // 팀원의 상수 정의
    const double imageSize = 50;
    const double imageHorizontalOffset = 22;
    const double imageVerticalOffset = 27;
    const double contentWidth = 350 - (16 * 2);
    const double titleTopOffset = 35;

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
            // 1. 이미지 (왼쪽 위)
            Positioned(
              left: imageHorizontalOffset,
              top: imageVerticalOffset,
              child: Image.asset(
                imagePath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
              ),
            ),

            // 2. 제목 (중앙 정렬)
            Positioned(
              left: 35,
              top: titleTopOffset,
              child: SizedBox(
                width: contentWidth,
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

// 🔹 하단 네비게이션 이미지 아이콘
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
        color: isActive ? null : Colors.black54,
      ),
    );
  }
}