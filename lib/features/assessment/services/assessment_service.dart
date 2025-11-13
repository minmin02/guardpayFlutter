import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardpayfront/features/assessment/models/quiz_model.dart';

/**
 * 진단(Assessment) 관련 백엔드 API 호출을 담당하는 서비스 클래스
 * - 퀴즈 정보 로드 및 사용자 답변 제출 기능을 포함합니다.
 */
class AssessmentService {
  // 백엔드 API의 기본 URL
  final String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // 1. ✅ 수정: 모든 퀴즈를 한 번에 로드하는 함수
  Future<List<Quiz>> fetchAssessmentQuizzes(String accessToken) async {
    final url = Uri.parse('$baseUrl/diagnoses/questions');

    try {
      print('📱 [Flutter] 요청 시작: $url');
      print('📱 [Flutter] 토큰 길이: ${accessToken.length}');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      // ✅ 응답 상세 로깅
      print('📱 [Flutter] 응답 코드: ${response.statusCode}');
      print('📱 [Flutter] 응답 본문 (처음 200자): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
          print('📱 [Flutter] JSON 파싱 성공');

          final Map<String, dynamic> data = jsonResponse['data'] ?? {};
          final List<dynamic> parts = data['parts'] ?? [];

          print('📱 [Flutter] parts 개수: ${parts.length}');

          List<Quiz> allQuizzes = [];

          for (var part in parts) {
            final List<dynamic> questions = part['questions'] ?? [];
            print('📱 [Flutter] part의 questions 개수: ${questions.length}');

            for (var questionJson in questions) {
              allQuizzes.add(Quiz.fromJson(questionJson));
            }
          }

          print('📱 [Flutter] 총 퀴즈 개수: ${allQuizzes.length}');
          return allQuizzes;

        } catch (parseError) {
          // ✅ JSON 파싱 에러를 명확히 구분
          print('❌ [Flutter] JSON 파싱 에러: $parseError');
          print('❌ [Flutter] 응답 본문: ${response.body}');
          throw Exception('데이터 파싱 오류: $parseError');
        }

      } else if (response.statusCode == 401) {
        print('❌ [Flutter] 401 에러 - 응답: ${response.body}');
        throw Exception('인증 오류 발생 (401). 유효하지 않은 토큰입니다. 재로그인이 필요합니다.');
      } else {
        print('❌ [Flutter] ${response.statusCode} 에러 - 응답: ${response.body}');
        throw Exception('퀴즈 로딩 실패: ${response.statusCode} - ${response.body}');
      }

    } on http.ClientException catch (e) {
      // ✅ 네트워크 에러 명확히 구분
      print('❌ [Flutter] 네트워크 에러: $e');
      throw Exception('네트워크 연결 오류: $e');
    } catch (e) {
      // ✅ 기타 예외를 그대로 다시 던지기 (재포장하지 않음)
      print('❌ [Flutter] 예상치 못한 에러: $e');
      rethrow;  // 원본 예외를 그대로 던짐
    }
  }


  // 2. ✅ 수정: 모든 퀴즈 답변을 한 번에 제출하고, 결과 ID를 받아, 최종 레벨을 조회하는 함수
  Future<String> submitAssessmentResults(List<Map<String, dynamic>> submissionData, String accessToken) async {

    // 2-1. API가 요구하는 'answers' 리스트 생성
    List<Map<String, dynamic>> answers = submissionData.map((data) {
      return {
        'quizId': data['quizId'] as int,
        // API는 'selectedAnswer'를 숫자로 받으므로 String을 int로 변환
        'selectedAnswer': int.parse(data['userAnswer'] as String),
      };
    }).toList();

    // 2-2. (POST /diagnoses/submit) 답변 일괄 제출
    final int historyId = await _submitAllAnswers(answers, accessToken);

    // 2-3. (GET /diagnoses/history/{id}) 제출 결과(레벨) 조회
    return _fetchFinalResult(historyId, accessToken);
  }

  // 2-2. (Helper) 답변 일괄 제출
  Future<int> _submitAllAnswers(List<Map<String, dynamic>> answers, String accessToken) async {
    final url = Uri.parse('$baseUrl/diagnoses/submit');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'answers': answers, // API 명세에 맞는 요청 본문
      }),
    );

    if (response.statusCode == 201) { // 201 Created
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      // 응답에서 historyId 추출
      final int historyId = jsonResponse['data']['historyId'] as int? ?? 0;
      if (historyId == 0) {
        throw Exception('응답에서 historyId를 찾을 수 없습니다.');
      }
      return historyId;
    } else {
      throw Exception('퀴즈 제출 실패: ${response.statusCode}');
    }
  }

  // 2-3. (Helper) 최종 진단 결과(레벨) 조회
  Future<String> _fetchFinalResult(int historyId, String accessToken) async {
    final url = Uri.parse('$baseUrl/diagnoses/history/$historyId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      print('✅ 최종 레벨 서버 응답: $jsonResponse'); // 로그 확인

      // ✅ 수정: 'finalGrade' 키에서 레벨 문자열 추출
      final String finalGrade = jsonResponse['data']['finalGrade'] as String? ?? 'UNKNOWN';
      print('✅ 파싱된 최종 레벨: $finalGrade');

      return finalGrade;
    } else {
      throw Exception('최종 레벨 조회 실패: ${response.statusCode}');
    }
  }
}