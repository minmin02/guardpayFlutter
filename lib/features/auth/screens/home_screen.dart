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
// _HomeScreenState 클래스 내부 변수로 추가
  final List<Map<String, String>> _searchOptions = [
    {'title': '역량 진단', 'route': '/assessment'},
    {'title': '금융 퀴즈', 'route': '/quizCategory'},
    {'title': '보이스피싱 예방', 'route': '/video'},
    {'title': '마이페이지', 'route': '/mypage'},
    {'title': '내 등급 조회', 'route': '/grade'}, // 새로 만든 등급 화면
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
                      // 1️⃣ 검색 로직
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, String>>.empty();
                        }
                        return _searchOptions.where((option) {
                          return option['title']!.contains(textEditingValue.text);
                        });
                      },

                      // 2️⃣ 선택 시 이동 로직
                      onSelected: (Map<String, String> selection) {
                        // 키보드 내리기
                        FocusManager.instance.primaryFocus?.unfocus();
                        print('선택된 메뉴: ${selection['title']}');
                        Navigator.pushNamed(context, selection['route']!);
                      },

                      // 3️⃣ 입력창 디자인 (기존 유지)
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

                      // 4️⃣ [수정됨] 자동완성 리스트 디자인
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.transparent, // Material 자체 색상은 투명하게
                            child: Container(
                              // ✅ 너비를 화면 너비에 맞게 조절 (약간의 여백 제외)
                              width: MediaQuery.of(context).size.width - 90,
                              constraints: const BoxConstraints(
                                maxHeight: 200, // ✅ 리스트 최대 높이 제한 (스크롤 가능하게)
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero, // 🚨 여기에 있던 'ㅇ' 오타 제거 완료
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