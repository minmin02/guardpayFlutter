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
            const SizedBox(height: 10),
            // 🔹 상단 검색창 + 알림/설정 아이콘 (이미지 버전)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽 메뉴 아이콘
                  const Icon(Icons.menu, color: Colors.black87, size: 26),
                  const SizedBox(width: 10),

                  // 검색창 아이콘 + 입력창
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해주세요.',
                        hintStyle: const TextStyle(color: Colors.grey),

                        border: OutlineInputBorder( // 경계선을 보이게 하여 아이콘과 텍스트 필드가 하나로 보이게 합니다.
                          borderRadius: BorderRadius.circular(8.0), // 원하는 만큼 둥글게 처리
                          borderSide: BorderSide.none, // 경계선 자체는 없앰 (배경색을 사용한다면)
                        ),
                        prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black54
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),
                  // 🔔 알림 아이콘 (이미지)
                  Image.asset(
                    'assets/images/alert_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),

                  // ⚙️ 설정 아이콘 (이미지)
                  Image.asset(
                    'assets/images/settings_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // 🔹 상단 노란 배너
            Container(
              width: 412,
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8C6),
                //borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // left와 top에 여백을 줘서 살짝 오른쪽/아래로 이동
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
                    // 텍스트만 원하는 위치에 배치하기 위해 Align 위젯을 추가합니다.
                    child: Padding(
                      // 텍스트 주변에 여백을 추가합니다.
                      // EdgeInsets.only를 사용하여 오른쪽(right)과 아래쪽(bottom)에만 여백을 줄 수 있습니다.
                      padding: const EdgeInsets.only(right: 13.0, bottom: 11.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: const Text(
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

            /// 🔹 아래 카드 3개
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCard(
                      title: '역량 진단 시작하기',
                      //subtitle: '나의 금융 이해도를 측정해보세요!',
                      imagePath: 'assets/images/checkBox_icon.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/abilityTest');
                      },
                    ),
                    _buildCard(
                      title: '금융 퀴즈 도전',
                      //subtitle: '맞히면 포인트가 쌓여요!',
                      imagePath: 'assets/images/quiz_icon2.png',
                      onTap: () {
                        Navigator.pushNamed(context, '/quiz');
                      },
                    ),
                    _buildCard(
                      title: '보이스피싱 예방 영상',
                      //subtitle: '보이스피싱 수법과 대처법에 대해 알아보세요!',
                      imagePath: 'assets/images/youtube_icon.png',
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
    //required subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // --- [1. 상수 정의] ---
    const double imageSize = 50;
    const double imageHorizontalOffset = 22;
    const double imageVerticalOffset = 27;

    // 💡 [새로 정의] 텍스트가 차지할 최대 너비 (카드의 패딩을 제외한 실질적 내용 영역의 폭)
    // 카드 너비 (350) - (왼쪽 패딩 + 오른쪽 패딩)
    // 카드의 내부 패딩(16)을 고려하여 계산합니다.
    const double contentWidth = 350 - (16 * 2);

    // 💡 [조정 가능] 제목과 부제목의 개별 위치 상수
    const double titleTopOffset = 35; // 제목이 위쪽에서 얼마나 띄워질지
    //const double subtitleTopOffset = titleTopOffset + 55; // 부제목이 위쪽에서 얼마나 띄워질지 (제목 위치 + 제목 높이)

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

            // 1. 이미지 (왼쪽 위쪽, 미세 조정 가능)
            Positioned(
              left: imageHorizontalOffset, // 왼쪽 위치
              top: imageVerticalOffset,    // 위쪽 위치
              child: Image.asset(
                imagePath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
              ),
            ),

            // 2. 제목 (Title) - 독립적으로 위치 조정
            Positioned(
              left: 35, // 이미지 공간 확보
              top: titleTopOffset,   // 💡 이 값을 조정하여 제목 위치 미세 조정
              child: SizedBox(
                width: contentWidth, // 카드의 폭에서 이미지+패딩을 뺀 나머지 공간
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

            // 3. 부제목 (Subtitle) - 독립적으로 위치 조정
            //if (subtitle != null) // subtitle이 있을 때만 표시
           //   Positioned(
            //    left: 0, // 이미지 공간 확보
             //   top: subtitleTopOffset, // 💡 이 값을 조정하여 부제목 위치 미세 조정
             //   child: SizedBox(
              //    width: contentWidth,
              //    child: Text(
               //     subtitle,
               //     textAlign: TextAlign.center,
                //    style: const TextStyle(
                 //     color: Colors.black54,
                 //     fontWeight: FontWeight.w500,
                  //    fontSize: 16,
                  //  ),
                 // ),
              //  ),
             // ),
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
