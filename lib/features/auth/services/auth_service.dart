import 'dart:convert'; // jsonEncode, jsonDecode를 사용하기 위해 필요
import 'package:http/http.dart' as http; // HTTP 통신을 위해 필요
import 'package:flutter/services.dart'; // [추가] PlatformException을 사용하기 위해 필요
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // [추가] 카카오 SDK
import 'dart:developer'; // 👈 1. dart:developer 라이브러리를 import 합니다.
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ 이 줄을 추가하세요.

class AuthService {
  // 실제 서버 환경에서는 여기에 Dio 인스턴스 등이 주입될 수 있습니다.
  //final String _apiUrl = 'http://10.0.2.2:8080/api/users'; // 기본 API 경로 설정
  static const String _tempAuthCode = '123456'; // 임시 이메일 인증 코드
  //final String _baseUrl = 'https://nonsusceptible-hyman-periproctal.ngrok-free.dev';
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  final _secureStorage = const FlutterSecureStorage(); // ✅ 토큰 저장을 위해 추가


  Future<void> signInWithGoogle() async {
    try {
      // 1. 스프링 부트의 구글 로그인 시작 URL
      // 💡 포트 번호(8080)는 본인 서버에 맞게 확인하세요.
      final url = Uri.parse('$_baseUrl/oauth2/authorization/google');

      // 2. 웹뷰를 열고, 스프링 부트가 리디렉션할 때까지 대기합니다.
      //    'guardpay'는 AndroidManifest.xml에 설정한 scheme 값입니다.
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: "guardpay",
      );

      // 3. 돌아온 URL에서 토큰을 추출합니다.
      final Uri callbackUri = Uri.parse(result);
      final accessToken = callbackUri.queryParameters['accessToken'];
      final refreshToken = callbackUri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        // 4. 토큰을 안전하게 기기에 저장합니다.
        await _secureStorage.write(key: 'accessToken', value: accessToken);
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);

        log('✅ 구글 로그인 성공! Access Token: $accessToken');

      } else {
        throw Exception('로그인에 성공했지만 토큰을 받아오지 못했습니다.');
      }

    } on PlatformException catch (e) {
      // 사용자가 웹뷰를 그냥 닫았을 경우를 처리합니다.
      if (e.code == 'CANCELED' || e.code == 'USER_CANCELLED') {
        log('ℹ️ 구글 로그인이 사용자에 의해 취소되었습니다.');
        // 에러를 던지지 않고 조용히 종료할 수도 있습니다.
        return;
      }
      throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      log('🚨 구글 로그인 중 알 수 없는 에러 발생: $e');
      throw Exception('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  // 1. 이메일 인증 코드를 요청하는 함수
  Future<String> requestAuthCode(String email) async {
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      // 클라이언트 측 유효성 검사 (실제 환경에서는 예외를 throw하거나 Error 객체를 반환)
      throw Exception('올바른 이메일 주소를 입력해주세요.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/password-reset-request'), // 👈 (가정) 회원가입용 코드 발송 API
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // 🚫 보안 위험: 서버가 보낸 '정답' 코드를 반환합니다.
        final code = body['verificationCode'];
        if (code == null) {
          throw Exception('API 응답에 인증 코드가 없습니다.');
        }
        log('[AuthService] 회원가입 코드 요청 성공. Code: $code');
        return code as String;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? '인증 코드 요청 실패');
      }
    } catch (e) {
      log('🚨 requestAuthCode 에러: $e');
      throw Exception('서버 통신 중 오류 발생: ${e.toString()}');
    }
  }

  // 2. 인증 코드를 확인하는 함수
  Future<bool> verifyAuthCode(String email, String code) async {
     //정의된 임시 인증 코드(_tempAuthCode)와 사용자가 입력한 코드를 비교합니다.
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
    final apiUrl = '$_baseUrl/api/auth/signup';

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

  /// 비밀번호 재설정을 위한 이메일 인증 코드를 요청합니다.
  Future<String> requestPasswordResetCode(String email) async {
    // TODO: 실제 서버의 '비밀번호 재설정용' 코드 요청 API와 연동해야 합니다.
    print('[AuthService] 비밀번호 재설정 코드 요청: $email');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/password-reset-request'), // 👈 (가정) 비밀번호 재설정 코드 발송 API
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // 🚫 보안 위험: 서버가 보낸 '정답' 코드를 반환합니다.
        final code = body['verificationCode'];
        if (code == null) {
          throw Exception('API 응답에 인증 코드가 없습니다.');
        }
        log('[AuthService] 비밀번호 재설정 코드 요청 성공. Code: $code');
        return code as String;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? '인증 코드 요청 실패');
      }
    } catch (e) {
      log('🚨 requestPasswordResetCode 에러: $e');
      throw Exception('서버 통신 중 오류 발생: ${e.toString()}');
    }
  }

  /// 비밀번호 재설정을 위한 인증 코드를 확인합니다.
  Future<void> verifyPasswordResetCode(String email, String code) async {
    // TODO: 실제 서버의 '비밀번호 재설정용' 코드 확인 API와 연동해야 합니다.
    if (code != _tempAuthCode) {
      throw Exception('인증 코드가 일치하지 않습니다.');
    }
    print('[AuthService] 비밀번호 재설정 코드 확인 완료: $email');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 새 비밀번호로 재설정하는 최종 요청을 보냅니다.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // --- 백엔드 API 없이 프론트엔드 시연을 위한 임시 코드 ---
    print('[AuthService] 비밀번호 변경 요청 시뮬레이션 시작 (서버 호출 안함)');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/password/reset'), // 👈 (가정) 최종 비밀번호 변경 API
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code, // 👈 화면(Screen)에서 자체 검증에 성공한 코드를 다시 보냅니다.
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        log('[AuthService] 비밀번호 변경 성공');
        return '비밀번호가 성공적으로 변경되었습니다.';
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? '비밀번호 변경 실패');
      }
    } catch (e) {
      log('🚨 resetPassword 에러: $e');
      throw Exception('서버 통신 중 오류 발생: ${e.toString()}');
    }

  }

  // [수정] 카카오 회원가입/로그인 처리 함수
  Future<Map<String, dynamic>> signupWithKakao() async {
    // 1. [추가] 기존 로그인 정보가 있다면 먼저 로그아웃 처리
    try {
      if (await AuthApi.instance.hasToken()) {
        await UserApi.instance.logout();
        print('기존 토큰 발견. 로그아웃 처리 완료.');
      }
    } catch (error) {
      print('로그아웃 처리 중 에러 발생 (무시): $error');
    }
    // 2. 카카오 SDK로 액세스 토큰 받기 (기존 로직과 동일)
    String? kakaoAccessToken;
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        kakaoAccessToken = (await TokenManagerProvider.instance.manager.getToken())?.accessToken;
      } catch (error) {
        if (error is PlatformException && error.code == 'CANCELED') {
          throw Exception('카카오톡 로그인이 취소되었습니다.');
        }
        try {
          await UserApi.instance.loginWithKakaoAccount();
          kakaoAccessToken = (await TokenManagerProvider.instance.manager.getToken())?.accessToken;
        } catch (accountError) {
          throw Exception('카카오 계정 로그인에 실패했습니다.');
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount();
        kakaoAccessToken = (await TokenManagerProvider.instance.manager.getToken())?.accessToken;
      } catch (accountError) {
        throw Exception('카카오 계정 로그인에 실패했습니다.');
      }
    }

    if (kakaoAccessToken == null) {
      throw Exception('카카오 액세스 토큰을 가져오는데 실패했습니다.');
    }

    log('🚀 Sending request to backend...');
    log('URL: $_baseUrl/api/auth/kakao');
    log('Kakao Access Token: $kakaoAccessToken');
    // 3. 백엔드 서버로 액세스 토큰 전송 (기존 로직과 동일)
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': kakaoAccessToken}),
    );


    // ✅ [로그 추가] 백엔드로부터 받은 응답의 상태 코드와 본문을 출력
    log('✅ Received response from backend!');
    log('Status Code: ${response.statusCode}');
    log('Response Body: ${response.body}');
    // [수정] 성공(200)과 실패 케이스를 나누어 처리
    if (response.statusCode == 200) {
      // 성공 시, 정상적으로 응답 본문 반환
      return jsonDecode(response.body);
    } else {
      // 실패 시, 서버가 보낸 구체적인 에러 메시지를 담아 Exception 발생
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('서버 통신 실패: ${errorBody['message'] ?? '알 수 없는 오류'}');
      } catch (e) {
        // 응답 본문이 JSON 형태가 아닐 경우를 대비한 예외 처리
        throw Exception('서버와 통신 중 오류가 발생했습니다. (상태 코드: ${response.statusCode})');
      }
    }
  }

  // [추가] 카카오 로그아웃 함수
  Future<void> kakaoLogout() async {
    try {
      await UserApi.instance.logout();
      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 실패 $error');
      throw Exception('로그아웃에 실패했습니다.');
    }
  }
}