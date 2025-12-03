import 'package:flutter/material.dart';
import 'package:guardpayfront/features/assessment/models/quiz_model.dart';
import 'package:guardpayfront/features/assessment/services/assessment_service.dart';
import 'package:guardpayfront/features/assessment/widgets/result_dialog.dart';
import 'package:guardpayfront/core/services/storage.dart';

// 1. 16진수 색상 코드를 편리하게 사용하기 위한 확장 함수
extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }
    return Colors.black;
  }
}

class AssessmentScreen extends StatefulWidget {
  static const String routeName = '/assessment-screen';

  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final AssessmentService _service = AssessmentService();
  Future<List<Quiz>>? _quizzesFuture;
  late List<Quiz> _quizzes;
  int _currentIndex = 0;
  int? _selectedOptionId;

  String? _accessToken;
  final storage = AppStorage.storage;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  // 새 메서드: 토큰을 읽고 퀴즈 로딩을 시작
  Future<void> _loadQuizData() async {
    // 저장소에서 토큰 읽기
    final token = await storage.read(key: 'accessToken');

    if (token == null) {
      print("🚨 퀴즈 로딩 실패: 저장된 토큰이 없습니다. 로그인 화면으로 이동합니다.");
      // 토큰이 없으면 로그인 화면으로 강제 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // 토큰과 퀴즈 Future를 설정하고 UI 업데이트
    setState(() {
      _accessToken = token;
      _quizzesFuture = _service.fetchAssessmentQuizzes(_accessToken!);
    });
  }

  void _nextQuestion() {
    if (_selectedOptionId == null) return; // 답변 선택 안 했으면 이동 불가
    // 선택된 인덱스(0, 1, 2, 3)에 1을 더하여 Option ID를 추정
    final currentQuiz = _quizzes[_currentIndex];

    _quizzes[_currentIndex] = currentQuiz.copyWith(
      // userSelectedAnswer에 선택된 키(예: "1", "2")를 저장
      userSelectedAnswer: _selectedOptionId.toString(),
    );

    setState(() {
      if (_currentIndex < _quizzes.length - 1) {
        _currentIndex++;
        _selectedOptionId = null;
      } else {
        _submitAssessment();
      }
    });
  }

  void _handleAnswerSelection(int optionId) {
    setState(() {
      _selectedOptionId = optionId;
    });
  }

  void _showResultDialog(BuildContext context, String level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ResultDialog(
          level: level,
          onConfirm: () {
            Navigator.of(context).pop();
            Navigator.pushNamed(context, '/home');
          },
        );
      },
    );
  }

  // 최종 제출 및 결과 조회 로직
  Future<void> _submitAssessment() async {
    // 제출할 데이터 구조 생성
    final List<Map<String, dynamic>> submissionData = _quizzes.map((quiz) {
      final String? selectedAnswerStr = quiz.userSelectedAnswer;

      // 서버가 요구하는 int 타입으로 변환 (선택 안 했으면 0 또는 적절한 예외 처리)
      int selectedOptionId = 0;
      if (selectedAnswerStr != null) {
        try {
          selectedOptionId = int.parse(selectedAnswerStr);
        } catch (e) {
          print('파싱 에러: 선택된 답변 ID ($selectedAnswerStr)가 유효한 정수가 아닙니다.');
        }
      }

      return {
        'quizId': quiz.id,
        // 'selectedOptionId' 키로 정수 값을 전달하도록 변경
        'selectedOptionId': selectedOptionId,
      };
    }).toList();

    try {
      final finalLevel = await _service.submitAssessmentResults(
        submissionData,
        _accessToken!,
      );

      // 성공 시 결과 팝업 표시
      _showResultDialog(context, finalLevel);
    } catch (e) {
      // 에러 발생 시 처리
      print('역량 진단 제출 중 오류 발생: $e');
      // 사용자에게 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: ${e.toString()}')),
        );
      }
    }
  }

  // 퀴즈 내용 빌드 메서드 (상태 접근 가능)
  Widget _buildQuizContent() {
    final currentQuiz = _quizzes[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 퀴즈 번호
        Padding(
          padding: const EdgeInsets.only(top: 7.0, left: 13.0),
          child: Text(
            'Quiz ${_currentIndex + 1}.',
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
        ),
        // 퀴즈 질문
        Padding(
          padding: const EdgeInsets.only(top: 28.0),
          child: Text(
            currentQuiz.question,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // 옵션 버튼 목록
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: currentQuiz.options.asMap().entries.map((entry) {
              final int index = entry.key;
              final option = entry.value;

              final int optionId = option.optionId;
              final String optionText = option.text;
              final int optionNumber = index + 1;

              bool isSelected = _selectedOptionId == optionId;

              return GestureDetector(
                onTap: () => _handleAnswerSelection(optionId),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 25.0),
                  padding: const EdgeInsets.symmetric(vertical: 17.5, horizontal: 22),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    '${optionNumber}. $optionText',
                    style: TextStyle(
                      fontSize: 17,
                      color: isSelected ? Colors.green.shade800 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 하단 버튼 빌드 메서드 (상태 접근 가능)
  Widget _buildBottomButton() {

    return Positioned(
      left: 33.0,
      right: 33.0,
      bottom: 40.0,
      child: ElevatedButton(
        // 답변 선택 시에만 버튼 활성화
        onPressed: _selectedOptionId != null ? _nextQuestion : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 53),
          backgroundColor: _selectedOptionId != null ? Colors.green.shade600 : Colors.green.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),

        child: Text(
          _currentIndex == _quizzes.length - 1 ? '제출하기' : '다음 문제로',
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 메인 빌드 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Quiz>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (_quizzesFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _quizzes = snapshot.data!;
            if (_quizzes.isEmpty) {
              return const Center(child: Text('퀴즈가 없습니다.'));
            }

            return Container(
              color: '#F9F5EC'.toColor(),
              child: SafeArea(
                child: Stack(
                  children: [
                    // 1. 뒤로 가기 버튼
                    Positioned(
                      top: 26.0,
                      left: 20.0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      ),
                    ),

                    // 2. 퀴즈 헤더
                    Positioned(
                      top: 80.0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 74, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.lightGreen.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            '금융 역량 진단 퀴즈',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 메인 퀴즈 박스
                    Positioned(
                      left: 33.0,
                      right: 33.0,
                      top: 180.0,
                      bottom: 140.0,
                      child: Container(
                        padding: const EdgeInsets.all(24.0), // 패딩 조정
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        // 퀴즈 내용 메서드 호출
                        child: _buildQuizContent(),
                      ),
                    ),
                    // 하단 버튼 메서드 호출
                    _buildBottomButton(),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('퀴즈를 불러오는 중 문제가 발생했습니다.'));
          }
        },
      ),
    );
  }
}