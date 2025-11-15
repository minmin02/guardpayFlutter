import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart';

import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

class QuizCategoryScreen extends StatefulWidget {
  const QuizCategoryScreen({super.key});

  @override
  State<QuizCategoryScreen> createState() => _QuizCategoryScreenState();
}

class _QuizCategoryScreenState extends State<QuizCategoryScreen> {
  final QuizService _quizService = QuizService();
  final _storage = AppStorage.storage;

  Future<List<QuizCategory>>? _categoriesFuture;
  Future<List<QuizProgress>>? _progressFuture;

  String? _accessToken;

  @override
  void initState() {
    super.initState();
    // ❗️ 화면 시작 시 토큰을 읽고 데이터 로딩 시작
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await _storage.read(key: 'accessToken');
    print("토큰 읽기 완료. 토큰: $token");

    if (token == null) {
      print("🚨 오류: 토큰이 null입니다.");
      return;
    }

    setState(() {
      _accessToken = token;
      _categoriesFuture = _quizService.getCategories();
      _progressFuture = _quizService.getProgress(_accessToken!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8EE),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 18.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //const SizedBox(height: 5),
            const Text(
              "학습 분야를 선택하세요",
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _categoriesFuture ?? Future.value([]),
                  _progressFuture ?? Future.value([])
                ]),
                builder: (context, snapshot) {
                  if (_categoriesFuture == null || _progressFuture == null) {
                    // _loadData가 아직 토큰을 못 가져온 경우
                    return const Center();
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("오류: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    return const Center(child: Text("데이터가 없습니다."));
                  }

                  final categories = snapshot.data![0] as List<QuizCategory>;
                  final progresses = snapshot.data![1] as List<QuizProgress>;
                  print("✅ [CategoryScreen] API가 반환한 progresses: $progresses");

                  if (categories.isEmpty) {
                    return const Center(child: Text("퀴즈 카테고리가 없습니다."));
                  }

                  final progressMap = {
                    for (var p in progresses) p.categoryId: p.progress
                  };

                  // 카테고리 목록을 동적으로 빌드
                  return ListView(
                    children: categories.map((category) {
                      // API에서 받은 progress 값 (예: 75.0)을 사용
                      double currentProgress =
                          progressMap[category.categoryId] ?? 0.0;

                      return buildCategoryCard(
                        context,
                        category.name, // 서버에서 받은 이름
                        currentProgress, // 서버에서 받은 진행률 (예: 75.0)
                        category.categoryId, // 서버에서 받은 ID
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryCard(
      BuildContext context, String title, double progress, int categoryId) {

    // ✅ 4. 수정: API에서 받은 0-100 범위의 progress 값을 0.0-1.0 범위로 변환
    // (progress / 100.0)을 사용
    // 혹시 progress가 1.0을 초과하는 경우를 대비해 1.0으로 제한
    final double progressRatio = (progress / 100.0).clamp(0.0, 1.0);
    const double barWidth = 300.0; // 프로그레스 바의 최대 너비

    return InkWell(
      // 탭 기능 추가
      onTap: () {
        Navigator.pushNamed(
          context,
          '/quiz',
          arguments: {
            'categoryId': categoryId,
            'categoryName': title,
            'progress': progress,
          },
        );
      },
      borderRadius: BorderRadius.circular(22),
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
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // progress bar background
                Container(
                  height: 10,
                  width: barWidth, // 최대 너비 고정
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // progress bar foreground
                Container(
                  height: 10,
                  // 4. 수정: progressRatio 사용
                  width: barWidth * progressRatio,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3ED597),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // check icon
                Positioned(
                  // 4. 수정: progressRatio 사용
                  left: (barWidth * progressRatio) - 14, // (아이콘 너비의 절반)
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCCFFE8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF3ED597),
                      size: 18,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
