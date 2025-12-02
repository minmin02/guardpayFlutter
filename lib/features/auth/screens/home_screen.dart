import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:guardpayfront/features/auth/screens/grade_screen.dart';
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

  final List<Map<String, String>> _searchOptions = [
    {'title': '역량 진단', 'route': '/assessment'},
    {'title': '금융 퀴즈', 'route': '/quizCategory'},
    {'title': '보이스피싱 예방', 'route': '/video'},
    {'title': '마이페이지', 'route': '/mypage'},
    {'title': '내 등급 조회', 'route': '/grade'},
  ];
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GradeScreen()),
                      );
                    },
                    child: const Icon(Icons.menu, color: Colors.black87, size: 26),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Autocomplete<Map<String, String>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, String>>.empty();
                        }
                        return _searchOptions.where((option) {
                          return option['title']!.contains(textEditingValue.text);
                        });
                      },

                      onSelected: (Map<String, String> selection) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        print('선택된 메뉴: ${selection['title']}');
                        Navigator.pushNamed(context, selection['route']!);
                      },

                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: '검색어를 입력해주세요.',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          ),
                        );
                      },

                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 90,
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['title']!),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),

                  const SizedBox(width: 12),
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

            // 🔹 상단 배너 - 로고 흰 박스 제거
            Container(
              width: double.infinity,
              height: 190,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF8DC),
                    Color(0xFFFFF0B3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 로고 (흰 박스 제거)
                    Image.asset(
                      'assets/images/main_logo-removebg-preview.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(width: 20),

                    // 텍스트
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '안전 송금,\n퀴즈로 배우자!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D2D2D),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB74D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '퀴즈 풀고 포인트 모으기',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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