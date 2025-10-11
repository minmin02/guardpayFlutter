import 'dart:convert'; // jsonEncode, jsonDecode를 사용하기 위해 필요
import 'package:http/http.dart' as http; // HTTP 통신을 위해 필요

class AuthService {
  // 실제 서버 환경에서는 여기에 Dio 인스턴스 등이 주입될 수 있습니다.
  final String _apiUrl = 'http://10.0.2.2:8080/api/users'; // 기본 API 경로 설정
  static const String _tempAuthCode = '123456'; // 임시 이메일 인증 코드

  // 1. 이메일 인증 코드를 요청하는 함수
  Future<bool> requestAuthCode(String email) async {
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      // 클라이언트 측 유효성 검사 (실제 환경에서는 예외를 throw하거나 Error 객체를 반환)
      throw Exception('올바른 이메일 주소를 입력해주세요.');
    }

    // TODO: 실제 서버 API 엔드포인트에 맞게 URL 수정 필요 (예: '/request-code')
    // 현재는 성공했다고 가정하고 true 반환
    print('이메일 인증 코드 요청: $email');
    await Future.delayed(const Duration(milliseconds: 500)); // API 지연 시뮬레이션
    return true;
  }

  // 2. 인증 코드를 확인하는 함수
  Future<bool> verifyAuthCode(String email, String code) async {
    // 정의된 임시 인증 코드(_tempAuthCode)와 사용자가 입력한 코드를 비교합니다.
    if (code != _tempAuthCode) { // TODO: 실제 인증 로직으로 대체 필요
      throw Exception('인증 코드가 일치하지 않습니다.');
    }
    print('인증 코드 확인 완료: $email');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // 3. 회원가입을 최종적으로 처리하는 함수
  Future<String> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    // API 주소
    const apiUrl = 'http://10.0.2.2:8080/api/auth/signup';

    // 서버에 보낼 데이터 (Dart의 Map)
    final signupData = {
      'email': email,
      'password': password,
      'nickname': nickname,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(signupData), // 데이터를 JSON 문자열로 인코딩
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('가입 성공 응답: ${response.body}');
        return '회원가입이 완료되었습니다!';
      } else {
        print('가입 실패 응답: ${response.body}');
        final errorBody = jsonDecode(response.body);
        // 서버에서 제공하는 오류 메시지 반환
        return errorBody['message'] ?? '가입에 실패했습니다.';
      }
    } catch (error) {
      print('가입 요청 실패: $error');
      throw Exception('서버와 통신할 수 없습니다.');
    }
  }
}