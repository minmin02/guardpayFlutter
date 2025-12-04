import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialLoginService {
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;
  SocialLoginService._internal();

  final _storage = AppStorage.storage;
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth';

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ✅ 카카오 로그인 완성
  Future<Map<String, dynamic>> loginWithKakao() async {
    try {
      print('🔵 [Kakao Login] 카카오 로그인 시작');

      // 1️⃣ 카카오에서 소셜 토큰 받기
      OAuthToken token;

      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print('✅ [Kakao Login] 카카오톡으로 로그인 성공');
        } catch (error) {
          print('⚠️ [Kakao Login] 카카오톡 로그인 실패, 웹으로 시도: $error');
          token = await UserApi.instance.loginWithKakaoAccount();
          print('✅ [Kakao Login] 카카오 계정으로 로그인 성공');
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
        print('✅ [Kakao Login] 카카오 계정으로 로그인 성공 (카카오톡 미설치)');
      }

      final kakaoAccessToken = token.accessToken;
      print('✅ [Kakao Login] 카카오 액세스 토큰 획득: ${kakaoAccessToken.substring(0, 20)}...');

      // 2️⃣ 카카오 사용자 정보 가져오기 (선택사항 - 디버깅용)
      try {
        User user = await UserApi.instance.me();
        print('✅ [Kakao Login] 사용자 정보:');
        print('   - ID: ${user.id}');
        print('   - 닉네임: ${user.kakaoAccount?.profile?.nickname}');
        print('   - 이메일: ${user.kakaoAccount?.email}');
      } catch (e) {
        print('⚠️ [Kakao Login] 사용자 정보 가져오기 실패: $e');
      }

      // 3️⃣ 카카오 토큰을 우리 백엔드로 전송
      print('🔵 [Kakao Login] 백엔드로 토큰 전송 시작...');
      final response = await http.post(
        Uri.parse('$baseUrl/kakao/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': kakaoAccessToken,
        }),
      );

      print('📩 [Kakao Login] 백엔드 응답 상태: ${response.statusCode}');

      // 4️⃣ 우리 백엔드 응답 처리
      return await _handleSocialLoginResponse(response, 'Kakao');

    } catch (e) {
      print('🚨 [Kakao Login] 카카오 로그인 실패: $e');
      return {
        'success': false,
        'message': '카카오 로그인에 실패했습니다: ${e.toString()}',
      };
    }
  }

  /// ✅ 구글 로그인 완성
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('🔵 [Google Login] 구글 로그인 시작');

      // 1️⃣ 구글에서 소셜 토큰 받기
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ [Google Login] 사용자가 로그인을 취소함');
        return {
          'success': false,
          'message': '구글 로그인이 취소되었습니다.',
        };
      }

      print('✅ [Google Login] 구글 계정 선택 완료: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final googleIdToken = googleAuth.idToken;

      if (googleIdToken == null) {
        print('🚨 [Google Login] ID 토큰을 가져올 수 없음');
        return {
          'success': false,
          'message': '구글 ID 토큰을 가져올 수 없습니다.',
        };
      }

      print('✅ [Google Login] 구글 ID 토큰 획득: ${googleIdToken.substring(0, 20)}...');

      // 2️⃣ 구글 토큰을 우리 백엔드로 전송
      print('🔵 [Google Login] 백엔드로 토큰 전송 시작...');
      final response = await http.post(
        Uri.parse('$baseUrl/google/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleIdToken,
        }),
      );

      print('📩 [Google Login] 백엔드 응답 상태: ${response.statusCode}');

      // 3️⃣ 우리 백엔드 응답 처리
      return await _handleSocialLoginResponse(response, 'Google');

    } catch (e) {
      print('🚨 [Google Login] 구글 로그인 실패: $e');
      return {
        'success': false,
        'message': '구글 로그인에 실패했습니다: ${e.toString()}',
      };
    }
  }

  /// ✅ 소셜 로그인 응답 처리 (공통 로직)
  Future<Map<String, dynamic>> _handleSocialLoginResponse(
      http.Response response, String provider) async {
    try {
      print('🔵 [$provider Login] 응답 처리 시작');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('✅ [$provider Login] 로그인 성공 - 서버 응답:');
        print('   $responseBody');

        final data = jsonDecode(responseBody);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final isNewUser = data['isNewUser'] ?? false; // 신규 회원 여부

        if (accessToken != null && refreshToken != null) {
          // 우리 서비스 토큰 저장
          await _storage.write(key: 'tokenType', value: 'Bearer');
          await _storage.write(key: 'accessToken', value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);

          // 저장 확인
          final checkA = await _storage.read(key: 'accessToken');
          final checkR = await _storage.read(key: 'refreshToken');
          print('✅ [$provider Login] 토큰 저장 완료:');
          print('   - Access Token 저장: ${checkA != null}');
          print('   - Refresh Token 저장: ${checkR != null}');

          // 신규 회원 여부에 따른 메시지
          String message = isNewUser
              ? '회원가입이 완료되었습니다! 환영합니다 🎉'
              : '로그인 성공!';

          return {
            'success': true,
            'message': message,
            'isNewUser': isNewUser,
          };
        } else {
          print('🚨 [$provider Login] 토큰 필드 누락');
          return {
            'success': false,
            'message': '토큰 정보가 누락되었습니다.',
          };
        }
      } else if (response.statusCode == 401) {
        // 인증 실패
        print('🚨 [$provider Login] 인증 실패 (401)');
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': errorBody['message'] ?? '소셜 로그인 인증에 실패했습니다.',
        };
      } else if (response.statusCode == 404) {
        // 엔드포인트 없음
        print('🚨 [$provider Login] 엔드포인트 없음 (404)');
        return {
          'success': false,
          'message': '서버에서 소셜 로그인 기능을 찾을 수 없습니다. 백엔드 설정을 확인해주세요.',
        };
      } else {
        // 기타 오류
        print('🚨 [$provider Login] 기타 오류 (${response.statusCode})');
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          print('   에러 내용: ${errorBody['message']}');
          return {
            'success': false,
            'message': errorBody['message'] ?? '로그인 실패',
          };
        } catch (e) {
          return {
            'success': false,
            'message': '서버 오류가 발생했습니다. (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('🚨 [$provider Login] 응답 처리 중 예외 발생: $e');
      return {
        'success': false,
        'message': '서버 응답 처리 중 오류가 발생했습니다.',
      };
    }
  }

  /// ✅ 로그아웃
  Future<void> logout() async {
    print('🔵 [Logout] 로그아웃 시작');

    // 우리 서비스 토큰 삭제
    await _storage.delete(key: 'tokenType');
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    print('✅ [Logout] 서비스 토큰 삭제 완료');

    // 카카오 로그아웃
    try {
      await UserApi.instance.logout();
      print('✅ [Logout] 카카오 로그아웃 완료');
    } catch (e) {
      print('⚠️ [Logout] 카카오 로그아웃 실패 (로그인 안 되어있었을 수 있음): $e');
    }

    // 구글 로그아웃
    try {
      await _googleSignIn.signOut();
      print('✅ [Logout] 구글 로그아웃 완료');
    } catch (e) {
      print('⚠️ [Logout] 구글 로그아웃 실패 (로그인 안 되어있었을 수 있음): $e');
    }

    print('✅ [Logout] 전체 로그아웃 완료');
  }
}
