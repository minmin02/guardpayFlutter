import 'package:flutter/material.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  final ApiService _api = ApiService();
  String? _grade;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGrade();
  }

  // API를 통해 등급 가져오기
  Future<void> _fetchGrade() async {
    try {
      final result = await _api.getMyGrade();

      if (mounted) {
        setState(() {
          _grade = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _grade = null;
          _isLoading = false;
        });
      }
      print('등급 조회 중 오류 발생: $e');
    }
  }

  // 등급 텍스트를 보기 좋게 변환 (예: "주의_필요" -> "주의 필요")
  String _formatGrade(String? grade) {
    if (grade == null) return "정보 없음";
    return grade.replaceAll('_', ' ');
  }

  // 등급에 따른 아이콘 색상 (옵션)
  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    if (grade.contains("안전")) return Colors.green;
    if (grade.contains("주의")) return Colors.orange;
    if (grade.contains("위험")) return Colors.red;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC), // 기존 앱 배경색 유지
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5EC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "내 등급 정보",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 등급 카드 디자인
            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded, // 방패 모양 아이콘
                    size: 80,
                    color: _getGradeColor(_grade),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "현재 나의 금융 등급",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatGrade(_grade),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 새로고침 버튼 (선택 사항)
            TextButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchGrade();
              },
              icon: const Icon(Icons.refresh, color: Colors.black54),
              label: const Text(
                "다시 불러오기",
                style: TextStyle(color: Colors.black54),
              ),
            )
          ],
        ),
      ),
    );
  }
}