import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // jsonDecode를 사용하기 위해 필요
import 'package:http/http.dart' as http; // http 사용을 위해 필요
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/social_login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. 서비스 인스턴스 초기화
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  //final _storage = const FlutterSecureStorage();
  final _storage = AppStorage.storage; // ✅ 교체
  final _socialLoginService = SocialLoginService(); // 추가

  // 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _socialLoginService.loginWithKakao();

      _showSnackBar(result['message']);

      if (result['success'] && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 구글 로그인 처리
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _socialLoginService.loginWithGoogle();

      _showSnackBar(result['message']);

      if (result['success'] && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  bool _isLoading = false;
  bool _obscureText = true;

  // 2. 일관된 SnackBar 표시를 위한 유틸리티 함수
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 3. 이메일/비밀번호 로그인 처리
  Future<void> _handleLogin() async {
    // 입력 유효성 검사
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }

    const apiUrl = 'http://10.0.2.2:8080/api/auth/login';
    final loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        // ⬇️ [수정] response.body 대신 response.bodyBytes를 UTF-8로 디코딩합니다.
        final responseBody = utf8.decode(response.bodyBytes);

        // ⬇️ [디버그] Flutter가 받은 응답 원본 확인
        print('✅ [Login Success] 서버 응답 본문 (UTF-8 디코딩): $responseBody');

        final data = jsonDecode(responseBody); // 디코딩된 문자열을 JSON 객체로 파싱

        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        // ⬇️ [디버그] 파싱된 토큰 값 확인
        print('Access Token from data: $accessToken');
        print('Refresh Token from data: $refreshToken');


        if (accessToken != null && refreshToken != null) {
          // 토큰 저장
          await _storage.write(key: 'tokenType', value: 'Bearer');
          await _storage.write(key: 'accessToken',  value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);

// 저장 확인 (중요)
          final checkA = await _storage.read(key: 'accessToken');
          final checkR = await _storage.read(key: 'refreshToken');
          final checkT = await _storage.read(key: 'tokenType');

          print('>>> saved? access=${checkA != null}, refresh=${checkR != null}');
          _showSnackBar('로그인 성공!');
          if (!mounted) return;
          // 홈 화면으로 이동 (로그인 페이지는 제거)
          Navigator.pushReplacementNamed(context, '/home');

        } else {
          // 🚨 서버가 토큰을 반환했지만, 필드가 누락된 경우
          _showSnackBar('로그인은 성공했지만, 토큰 필드(accessToken/refreshToken)가 누락되었습니다. 서버의 응답 구조를 확인해주세요.');
        }
      } else {
        // 오류 처리
        // ⬇️ 오류 응답도 UTF-8 디코딩을 시도합니다.
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        _showSnackBar(errorBody['message'] ?? '로그인 실패: 서버 오류');
      }
    } catch (e) {
      print('🚨 로그인 요청 실패: $e'); // 실제 예외 로깅
      _showSnackBar('서버와 통신할 수 없습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 5),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 350,
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: '이메일',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 13.0, horizontal: 15.0),
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 13.0, horizontal: 15.0),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('로그인'),
              ),
              const SizedBox(height: 13),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('회원가입'),
              ),
              const SizedBox(height: 7),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reset');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('임시 비밀번호 발급받기 >'),
              ),
              const SizedBox(height: 18),
              // ✅ 수정: 소셜 로그인 버튼 연결
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _handleKakaoLogin, // ✅ 카카오 로그인 연결
                    child: Opacity(
                      opacity: _isLoading ? 0.5 : 1.0, // 로딩 중일 때 비활성화 표시
                      child: Image.asset(
                        'assets/images/kakao_logo.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  GestureDetector(
                    onTap: _isLoading ? null : _handleGoogleLogin, // ✅ 구글 로그인 연결
                    child: Opacity(
                      opacity: _isLoading ? 0.5 : 1.0, // 로딩 중일 때 비활성화 표시
                      child: Image.asset(
                        'assets/images/google_logo.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

