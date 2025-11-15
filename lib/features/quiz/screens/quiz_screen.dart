import 'package:flutter/material.dart';

import '../../../core/services/storage.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../widgets/quiz_dialog.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- Services & Storage ---
  final QuizService _quizService = QuizService();
  final _storage = AppStorage.storage;
  String? _accessToken;

  // --- Navigation Arguments ---
  late int _categoryId;
  String _categoryName = "퀴즈"; // 기본값
  double _progress = 0.0; // 기본값

  // --- State Variables ---
  bool _isLoadingList = true; // 퀴즈 '목록' 로딩 중
  bool _isLoadingDetail = false; // 퀴즈 '상세' 로딩 중
  bool _isSubmitting = false; // 정답 '제출' 중
  bool _isAnswered = false; // 현재 퀴즈를 푼 상태인지

  List<QuizSummary> _quizSummaries = []; // 퀴즈 목록 (플레이리스트)
  int _currentQuizIndex = 0; // 현재 퀴즈 인덱스
  QuizDetail? _currentQuizDetail; // 현재 표시할 퀴즈의 상세 정보
  SubmitResult? _submitResult; // 정답 제출 결과
  int? _selectedOptionId; // 사용자가 선택한 선택지 ID
  int _totalPointsEarned = 0; // 총 점수
  bool _isQuizCompleted = false;

  String get _progressKey => 'quiz_progress_cat_${_categoryId}';
  String get _pointsKey => 'quiz_points_cat_${_categoryId}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 네비게이션 인자 받기 (최초 1회)
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _categoryId = args['categoryId'];
    _categoryName = args['categoryName'];
    _progress = args['progress'];

    if (_accessToken == null) {
      _loadData();
    }
  }

  // 화면을 나갈 때 현재 퀴즈 진행 상황을 로컬 저장소에 저장
  @override
  void dispose() {
    if (!_isLoadingList && _quizSummaries.isNotEmpty && !_isQuizCompleted) {
      // 퀴즈가 완료되지 않은 상태(목록 길이보다 인덱스가 작을 때)에만 저장
      if (_currentQuizIndex < _quizSummaries.length) {
        _storage.write(key: _progressKey, value: _currentQuizIndex.toString());
        _storage.write(key: _pointsKey, value: _totalPointsEarned.toString());
        print("💾 퀴즈 진행 상황 저장됨: Index $_currentQuizIndex, Points $_totalPointsEarned");
      }
    }
    super.dispose();
  }

  // 데이터 로딩 (토큰 -> 퀴즈 목록 -> 퀴즈 1 상세)
  Future<void> _loadData() async {
    // 1. 토큰 읽기
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      print("🚨 QuizScreen: 토큰이 없습니다. 이전 화면으로 돌아갑니다.");
      if (mounted) Navigator.pop(context);
      return;
    }
    _accessToken = token;

    // 2. 퀴즈 목록 불러오기
    try {
      setState(() {
        _isLoadingList = true;
      });
      _quizSummaries = await _quizService.getQuizzesForCategory(_categoryId);
      setState(() {
        _isLoadingList = false;
      });

      // 3. 퀴즈 목록 성공 시
      if (_quizSummaries.isNotEmpty) {
        // 저장된 진행 상황 로드
        final savedIndexStr = await _storage.read(key: _progressKey);
        final savedPointsStr = await _storage.read(key: _pointsKey);

        int startIndex = 0;
        int startPoints = 0;

        // 저장된 인덱스 복원, 유효성 검사
        if (savedIndexStr != null && int.tryParse(savedIndexStr) != null) {
          int loadedIndex = int.parse(savedIndexStr);
          if (loadedIndex < _quizSummaries.length) {
            startIndex = loadedIndex;
          }
        }

        // 저장된 점수 복원
        if (savedPointsStr != null && int.tryParse(savedPointsStr) != null) {
          startPoints = int.parse(savedPointsStr);
        }

        // 상태 업데이트 및 퀴즈 로드 시작
        setState(() {
          _currentQuizIndex = startIndex;
          _totalPointsEarned = startPoints;
        });

        _loadQuizDetail(startIndex);
      } else {
        print("🤔 이 카테고리에 퀴즈가 없습니다.");
      }
    } catch (e) {
      print("🚨 퀴즈 목록 로딩 실패: $e");
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  // 특정 인덱스의 퀴즈 상세 정보 불러오기
  Future<void> _loadQuizDetail(int index) async {
    if (index < 0 || index >= _quizSummaries.length) return;

    setState(() {
      _currentQuizIndex = index;
      _isLoadingDetail = true;
      _isAnswered = false;
      _selectedOptionId = null;
      _submitResult = null;
    });

    try {
      final quizId = _quizSummaries[index].quizId;
      _currentQuizDetail = await _quizService.getQuizDetail(quizId);
    } catch (e) {
      print("🚨 퀴즈 상세 로딩 실패: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  // 정답 제출
  Future<void> _submitAnswer() async {
    if (_selectedOptionId == null || _accessToken == null || _isAnswered) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      _submitResult = await _quizService.submitAnswer(
        _currentQuizDetail!.quizId,
        _selectedOptionId!,
        _accessToken!,
      );
      setState(() {
        _isAnswered = true;

        // 정답일 경우에만 총점에 현재 퀴즈 점수 누적
        if (_submitResult!.isCorrect) {
          _totalPointsEarned += _currentQuizDetail!.point;
        }
      });
    } catch (e) {
      print("🚨 정답 제출 실패: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // 다음 문제로 이동하거나 완료 시 팝업창 띄우기
  void _nextQuiz() {
    if (_currentQuizIndex + 1 < _quizSummaries.length) {
      // 다음 퀴즈 로드
      _loadQuizDetail(_currentQuizIndex + 1);
    } else {
      _isQuizCompleted = true;

      // 모든 퀴즈 완료
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // ❗️ 새로 만든 QuizCompletionDialog 사용
          return QuizDialog(
            title: "학습 완료!", // 기존 제목
            content: "총 ${_totalPointsEarned}p를 획득했습니다.", // 기존 내용
            onConfirm: () async {
              print("DEBUG_KEY: Deleting progress key: $_progressKey");

              await _storage.delete(key: _progressKey);
              await _storage.delete(key: _pointsKey);
              print("🗑️ 퀴즈 완료: 로컬 저장된 진행 상황이 리셋되었습니다.");

              final checkIndex = await _storage.read(key: _progressKey);
              print("DEBUG_CHECK: Index after delete: $checkIndex");

              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 퀴즈 스크린 닫기
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8EE),
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 8.0, top: 18.0),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  // --- Body 빌더 ---
  Widget _buildBody() {
    if (_isLoadingList) {
      return const Center();
    }
    if (_quizSummaries.isEmpty) {
      return const Center(child: Text("이 카테고리에 퀴즈가 없습니다."));
    }
    if (_isLoadingDetail || _currentQuizDetail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 퀴즈 UI 빌드
    final quiz = _currentQuizDetail!;
    final double progressRatio = (_progress / 100.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학습 진행률 (동적)
            const SizedBox(height: 25),
            Center( // ⬅️ Center 위젯으로 감싸서 수평 중앙 정렬
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // ⬅️ Row 내부 요소도 중앙 정렬 (필요하다면)
                children: [
                  Text(
                    "$_categoryName 학습 진행률",
                    style: const TextStyle(
                      fontSize: 22, // ⬅️ 22로 변경된 폰트 크기 사용
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${_progress.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Progress Bar (동적) - 수정된 로직
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  // Stack을 사용해 회색 바와 초록색 바를 겹칩니다.
                  child: Stack(
                    children: [
                      // 1. 회색 배경 바 (항상 전체 너비)
                      Container(
                        width: constraints.maxWidth,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // 2. 초록색 진행률 바 (너비가 0%일 수 있음)
                      Container(
                        width: constraints.maxWidth * progressRatio,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3ED597),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 50),

            // Quiz 카드 (동적)
            Container(
              padding:
              const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제 번호 + 점수 (동적)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7.0, left: 13.0),
                        child: Text(
                          'Quiz ${_currentQuizIndex + 1}.',
                          style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold)
                          ,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "${quiz.point}p", // ⬅️ 동적
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(top: 28.0),
                    child: Text(
                      quiz.question,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 선택지 리스트 (동적)
                  Column(
                    // ❗️ quiz.options를 사용해 동적으로 생성
                    children: quiz.options.asMap().entries.map((entry) {
                      int index = entry.key;
                      QuizOption option = entry.value;
                      return answerButton(
                        option: option,
                        index: index,
                        selectedOptionId: _selectedOptionId,
                        isAnswered: _isAnswered,
                        submitResult: _submitResult,
                        onTap: () {
                          // 정답을 제출하지 않은 상태에서만 선택 가능
                          if (!_isAnswered) {
                            setState(() {
                              _selectedOptionId = option.optionId;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // '정답 제출' 또는 '다음 문제로' 버튼 (동적)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(), // ⬅️ 동적
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // ❗️ 상태에 따라 다른 함수 호출
                      onPressed: _isSubmitting
                          ? null // 제출 중 비활성화
                          : (_isAnswered ? _nextQuiz : _submitAnswer),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isAnswered ? "다음 문제로" : "정답 제출", // ⬅️ 동적
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          // ❗️ 선택해야 버튼 활성화
                          color: _selectedOptionId == null && !_isAnswered
                              ? Colors.white
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets & Methods ---

  // 버튼 색상 결정
  Color _getButtonColor() {
    if (!_isAnswered) {
      // 정답 제출 전
      return _selectedOptionId != null
          ? Colors.green // 선택함 (초록)
          : Colors.grey.shade300; // 선택 안 함 (회색)
    } else {
      // 정답 제출 후
      return _submitResult!.isCorrect
          ? Colors.green // 정답 (초록)
          : Colors.red.shade400; // 오답 (빨강)
    }
  }

  // 선택지 버튼 위젯 (상태에 따라 UI 변경)
  Widget answerButton({
    required QuizOption option, // ❗️ QuizOption 객체를 받음
    required int? selectedOptionId,
    required bool isAnswered,
    required SubmitResult? submitResult,
    required VoidCallback onTap,
    required int index,
  }) {
    bool isSelected = selectedOptionId == option.optionId;

    // 테두리 색상 결정
    Color borderColor = Colors.grey.shade300;
    Color? iconColor;

    if (isAnswered && isSelected) {
      // 정답 제출 후, 내가 선택한 옵션
      if (submitResult!.isCorrect) {
        borderColor = Colors.green; // 정답 (초록)
        iconColor = Colors.green;
      } else {
        borderColor = Colors.red.shade400; // 오답 (빨강)
        iconColor = Colors.red.shade400;
      }
    } else if (!isAnswered && isSelected) {
      // 정답 제출 전, 내가 선택한 옵션
      borderColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${index + 1}. ${option.optionText}", // ⬅️ 동적
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.grey.shade700,
                ),
              ),
            ),
            if (isAnswered && isSelected) // 정답/오답 아이콘
              Icon(
                submitResult!.isCorrect ? Icons.check_circle : Icons.cancel,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }
}