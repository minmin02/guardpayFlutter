import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // SnackBar 등 Context가 필요한 곳에서 HTTP 라이브러리를 사용하기 위해 필요
import 'dart:convert';

// 분리된 서비스와 위젯을 임포트합니다.
import '../services/auth_service.dart';
import '../widgets/email_auth_section.dart'; // <--- EmailAuthSection 임포트 유지 및 정리
import '../widgets/auth_input_field.dart'; // <--- 중복 임포트 제거 후 하나만 유지

// 회원가입 화면
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. 서비스 인스턴스 및 상태 관리
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>(); // 폼 유효성 검사를 위한 키

  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _termsAgreed = false;
  bool _isCodeRequested = false; // 인증 코드가 요청되었는가?
  bool _isCodeVerified = false; // 인증 코드가 확인되었는가?
  bool _isLoading = false; // 로딩 상태

  // 2. 인증 코드 요청 핸들러
  Future<void> _handleCodeRequest() async {
    setState(() { _isLoading = true; });
    try {
      await _authService.requestAuthCode(_emailController.text);
      setState(() {
        _isCodeRequested = true;
        _authCodeController.clear(); // 새 요청 시 코드 초기화
      });
      _showSnackBar('인증 코드가 이메일로 전송되었습니다.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 3. 인증 코드 확인 핸들러
  Future<void> _handleCodeVerify() async {
    setState(() { _isLoading = true; });
    try {
      await _authService.verifyAuthCode(_emailController.text, _authCodeController.text);
      setState(() {
        _isCodeVerified = true;
      });
      _showSnackBar('이메일 인증이 성공적으로 완료되었습니다.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 4. '가입하기' 버튼 함수 (최종 제출)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return; // 폼 유효성 검사 실패 시 종료
    }

    // 추가 로직 유효성 검사
    if (_passwordController.text != _passwordConfirmController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!_isCodeVerified) {
      _showSnackBar('이메일 인증을 완료해주세요.');
      return;
    }
    if (!_termsAgreed) {
      _showSnackBar('약관에 동의해주세요.');
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final message = await _authService.signup(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      );
      _showSnackBar(message);
      // TODO: 가입 성공 후 로그인 화면으로 이동
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 간결한 SnackBar 표시 유틸리티
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 리소스 해제
  @override
  void dispose() {
    _emailController.dispose();
    _authCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 배경색과 동일
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // TODO: 실제 라우팅에 맞게 수정
        ),
      ),
      // 키보드가 올라올 때 화면이 가려지지 않도록 스크롤 가능하게 만듭니다.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GuardPay 로고
              const Text(
                'GuardPay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6AA84F),
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // 1. 이메일 인증 섹션 (분리된 위젯 사용)
              EmailAuthSection(
                emailController: _emailController,
                codeController: _authCodeController,
                isCodeRequested: _isCodeRequested,
                isCodeVerified: _isCodeVerified,
                onCodeRequest: _handleCodeRequest,
                onCodeVerify: _handleCodeVerify,
              ),
              const SizedBox(height: 15),

              // 2. 비밀번호 입력 (AuthInputField 사용)
              const Text('비밀번호 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField( // <-- AuthInputField 적용
                controller: _passwordController,
                hintText: '비밀번호',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 8) {
                    return '비밀번호는 8자 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AuthInputField( // <-- AuthInputField 적용
                controller: _passwordConfirmController,
                hintText: '비밀번호 재입력',
                isPassword: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // 3. 닉네임 입력 (AuthInputField 사용)
              const Text('닉네임 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField( // <-- AuthInputField 적용
                controller: _nicknameController,
                hintText: '닉네임',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // 4. 약관 동의
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Row(
                  children: [
                    Checkbox(
                      value: _termsAgreed,
                      onChanged: (value) => setState(() { _termsAgreed = value ?? false; }),
                    ),
                    const Text('약관 전체 동의'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. 가입하기 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2
                    )
                )
                    : const Text(
                    '가입하기',
                    style: TextStyle(color: Colors.white)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
