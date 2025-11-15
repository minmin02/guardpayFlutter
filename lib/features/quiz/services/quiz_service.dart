import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/quiz_models.dart';

class QuizService {
  final String _baseUrl = "http://10.0.2.2:8080/api/quiz";

  // HTTP 응답 공통 처리
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));

      if (body['status'] == 200) {
        return body['data']; // 성공 시 'data' 객체 반환
      } else {
        throw Exception('API Error (${body['status']}): ${body['message']}');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  // 인증 헤더 생성
  Map<String, String> _authHeaders(String accessToken) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $accessToken', // ❗️ JWT 토큰 전송
    };
  }

  // 1. 카테고리 목록 조회 (GET /api/quiz/categories)
  Future<List<QuizCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories'));
      final data = _handleResponse(response);

      // 'categories' 키 아래의 동적 리스트를 QuizCategory 객체 리스트로 매핑
      List<dynamic> categoryList = data['categories'];
      return categoryList.map((json) => QuizCategory.fromJson(json)).toList();
    } catch (e) {
      print('getCategories 오류: $e');
      rethrow;
    }
  }

  // 2. 카테고리별 퀴즈 목록 조회 (GET /api/quiz/{categoryId}/list)
  Future<List<QuizSummary>> getQuizzesForCategory(int categoryId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$categoryId/list'));
      final data = _handleResponse(response);

      // 'quizzes' 키 아래의 동적 리스트를 QuizSummary 객체 리스트로 매핑
      List<dynamic> quizList = data['quizzes'];
      return quizList.map((json) => QuizSummary.fromJson(json)).toList();
    } catch (e) {
      print('getQuizzesForCategory 오류: $e');
      rethrow;
    }
  }

  // 3. 퀴즈 상세 조회 (GET /api/quiz/{quizId})
  Future<QuizDetail> getQuizDetail(int quizId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$quizId'));
      final data = _handleResponse(response);

      return QuizDetail.fromJson(data);

    } catch (e) {
      print('getQuizDetail 오류: $e');
      rethrow;
    }
  }

  // 4. 퀴즈 정답 제출 (POST /api/quiz/{quizId}/submit)
  Future<SubmitResult> submitAnswer(int quizId, int selectedOptionId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$quizId/submit'),
        headers: _authHeaders(accessToken),
        body: json.encode({
          'selectedOptionId': selectedOptionId,
        }),
      );

      final data = _handleResponse(response);
      return SubmitResult.fromJson(data);
    } catch (e) {
      print('submitAnswer 오류: $e');
      rethrow;
    }
  }

  // 5. 퀴즈 진행률 조회 (GET /api/quiz/progress)
  Future<List<QuizProgress>> getProgress(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/progress'),
        headers: _authHeaders(accessToken),
      );

      final data = _handleResponse(response);
      List<dynamic> progressList = data['progress'];
      return progressList.map((json) => QuizProgress.fromJson(json)).toList();
    } catch (e) {
      print('getProgress 오류: $e');
      rethrow;
    }
  }
}