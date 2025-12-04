import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 SDK
import 'dart:developer';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:guardpayfront/core/services/storage.dart'; // ⬅️ 이걸 써야 함
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // ⬇️ [수정됨] 1. 소셜 로그인용 (ngrok)
  // ❗️ .env 파일에 API_BASE_URL=https://your-ngrok-url.ngrok-free.dev
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://DEFAULT_NGROK_URL';

  // ⬇️ [수정됨] 2. 폼 회원가입/비번찾기용 (고정 IP)
  final String _localBaseUrl = 'http://10.0.2.2:8080';

  final _secureStorage = AppStorage.storage;
  static const String _tempAuthCode = '123456'; // 임시 이메일 인증 코드

  /// === 소셜 로그인 (Google) ===
  Future<void> signInWithGoogle() async {
    try {
      // 1. 스프링 부트의 구글 로그인 시작 URL 설정 (ngrok 사용)
      final url = Uri.parse('$_baseUrl/oauth2/authorization/google');

      // 2. 웹뷰를 열고, 리디렉션 대기
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: "guardpay",
      );

      // 3. 돌아온 URL에서 토큰을 추출
      final Uri callbackUri = Uri.parse(result);
      final accessToken = callbackUri.queryParameters['accessToken'];
      final refreshToken = callbackUri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        // 4. 토큰을 안전하게 저장
        await _secureStorage.write(key: 'accessToken', value: accessToken);
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);

        log('✅ [Google Auth] 구글 로그인 성공! 토큰 저장 완료.');
      } else {
        throw Exception('로그인에는 성공했지만 토큰을 받아오지 못했습니다.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED' || e.code == 'USER_CANCELLED') {
        log('ℹ️ [Google Auth] 사용자에 의해 로그인이 취소되었습니다.');
        return;
      }
      throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      log('🚨 [Google Auth] 알 수 없는 에러 발생: $e');
      throw Exception('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }


  /// === 일반 회원가입 & 인증 ===
  // 이메일 인증 코드 요청 함수
  Future<bool> requestAuthCode(String email) async {
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      throw Exception('올바른 이메일 주소를 입력해주세요.');
    }

    // TODO: 실제 서버 API 엔드포인트에 맞게 URL 수정 필요 (예: '/request-code')
    // ❗️[참고] 이 API도 실제로는 고정 IP(_localBaseUrl)를 써야 합니다.
    log('[Email Auth] 인증 코드 요청: $email (시뮬레이션)');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // 인증 코드 확인 함수
  Future<bool> verifyAuthCode(String email, String code) async {
    // TODO: 실제 인증 로직으로 대체 필요
    // ❗️[참고] 이 API도 실제로는 고정 IP(_localBaseUrl)를 써야 합니다.
    if (code != _tempAuthCode) {
      throw Exception('인증 코드가 일치하지 않습니다.');
    }
    log('[Email Auth] 인증 코드 확인 완료: $email');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // 회원가입 최종 처리 함수
  Future<String> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {

    // ⬇️ [수정됨] 폼 회원가입은 ngrok이 아닌 고정 IP(_localBaseUrl)를 사용합니다.
    final apiUrl = '$_localBaseUrl/api/auth/signup';

    // 서버에 보낼 JSON 데이터
    final signupData = {
      'email': email,
      'password': password,
      'nickname': nickname,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl), // ⬅️ _localBaseUrl이 적용된 apiUrl 사용
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(signupData),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('[Signup] 가입 성공 응답: ${response.body}');
        return responseBody['message'] ?? '회원가입이 성공적으로 완료되었습니다.';
      } else {
        log('🚨 [Signup] 가입 실패 응답: ${response.body}');
        throw Exception(responseBody['message'] ?? '회원가입에 실패했습니다.');
      }
    } catch (error) {
      print('🚨 가입 요청 실패: $error');
      throw Exception('서버와 통신할 수 없습니다.');
    }
  }


  /// === 임시 비밀번호 발급 ===
  Future<bool> requestPasswordResetCode(String email) async {
    log('[Password Reset] 임시 비밀번호 발급 요청: $email');

    try {
      final response = await http.post(
        // ⬇️ [수정됨] 비밀번호 찾기도 고정 IP(_localBaseUrl)를 사용합니다.
        Uri.parse('$_localBaseUrl/api/auth/password-reset-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        log('✅ [Password Reset] 임시 비밀번호 발급 요청 성공. 이메일 발송됨.');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? '인증 코드 요청 실패');
      }
    } catch (e) {
      log('🚨 [Password Reset] requestPasswordResetCode 에러: $e');
      throw Exception('서버 통신 중 오류 발생: ${e.toString()}');
    }
  }


  /// === 소셜 로그인 (Kakao) ===
  // 회원가입 & 로그인 처리 함수
  Future<Map<String, dynamic>> signupWithKakao() async {
    // 1. 기존 로그인 정보가 있다면 먼저 로그아웃 처리 (클린 시작)
    try {
      if (await AuthApi.instance.hasToken()) {
        await UserApi.instance.logout();
        log('[Kakao Auth] 기존 토큰 발견. 로그아웃 처리 완료.');
      }
    } catch (error) {
      log('⚠️ [Kakao Auth] 로그아웃 처리 중 에러 발생 (무시): $error');
    }

    // 2. 카카오 SDK로 액세스 토큰 받기 (생략)
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

    log('🚀 [Kakao Auth] 백엔드 서버로 토큰 전송 시작.');

    // 3. 백엔드 서버로 액세스 토큰 전송 (ngrok 사용)
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': kakaoAccessToken}),
    );

    // 4. 응답 처리 (생략)
    log('✅ [Kakao Auth] 서버 응답 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('서버 통신 실패: ${errorBody['message'] ?? '알 수 없는 오류'}');
      } catch (e) {
        throw Exception('서버와 통신 중 오류가 발생했습니다. (상태 코드: ${response.statusCode})');
      }
    }
  }


  String _mask(String? t) =>
      (t == null || t.length <= 12) ? '***' : '${t.substring(0, 6)}...${t.substring(t.length - 4)}';

  /// === 토큰 갱신 (Refresh Token) ===
  // JWT 갱신 API를 호출하고 성공 시 새 토큰을 저장하는 함수
  Future<bool> checkAndRefreshTokens(String refreshToken) async {
    final uri = Uri.parse('$_localBaseUrl/api/auth/reissue');
    print('>>> [AUTH] enter checkAndRefreshTokens (uri: $uri)');

    String? _jwtType(String jwt) {
      try {
        final p = jwt.split('.');
        if (p.length != 3) return null;
        String norm(String s) => s.replaceAll('-', '+').replaceAll('_', '/')
            .padRight((s.length + 3) ~/ 4 * 4, '=');
        final payload = utf8.decode(base64.decode(norm(p[1])));
        return (jsonDecode(payload)['type'] as String?)?.toLowerCase();
      } catch (_) { return null; }
    }

    Future<bool> _apply(http.Response res) async {
      final bodyStr = utf8.decode(res.bodyBytes);
      Map<String, dynamic> data = {};
      try { data = jsonDecode(bodyStr); } catch (_) {}

      String? newAccess  = (data['accessToken']  ?? data['access_token']) as String?;
      String? newRefresh = (data['refreshToken'] ?? data['refresh_token']) as String?;
      // 헤더(Bearer)로 access를 줄 수도 있음
      final hb = res.headers['authorization'];
      final headerAccess = hb?.replaceFirst(RegExp(r'Bearer\s+', caseSensitive:false), '');
      newAccess ??= headerAccess;

      // 타입 안전장치
      if (newAccess  != null && _jwtType(newAccess)  != 'access')  newAccess  = null;
      if (newRefresh != null && _jwtType(newRefresh) != 'refresh') newRefresh = null;

      if (newAccess == null) return false;
      await _secureStorage.write(key: 'accessToken', value: newAccess);
      if (newRefresh != null) {
        await _secureStorage.write(key: 'refreshToken', value: newRefresh);
      }
      return true;
    }

    try {
      print('>>> [AUTH] Attempt 1 (Header): Bearer ${_mask(refreshToken)}');

      // 1) 헤더(Bearer refresh) 방식
      var res = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      });
      print('>>> [AUTH] Attempt 1 (Header) Result: status=${res.statusCode}, body=${utf8.decode(res.bodyBytes)}');

      if (res.statusCode == 200 && await _apply(res)) return true;
      print('>>> [AUTH] Attempt 2 (Body): JSON');

      // 2) 바디(JSON) 방식 폴백
      res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      print('>>> [AUTH] Attempt 2 (Body) Result: status=${res.statusCode}, body=${utf8.decode(res.bodyBytes)}');

      if (res.statusCode == 200 && await _apply(res)) return true;
      print('>>> [AUTH] Both attempts failed. Returning false.');

      return false;
    } catch (e) {
      print('>>> [AUTH] Exception caught: $e. Returning false.');

      return false;
    }
  }



  // 로그아웃 함수
  Future<void> kakaoLogout() async {
    try {
      await UserApi.instance.logout();
      log('[Kakao Auth] 로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      log('🚨 [Kakao Auth] 로그아웃 실패: $error');
      throw Exception('로그아웃에 실패했습니다.');
    }
  }
}



