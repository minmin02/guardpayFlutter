import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // AuthService 사용

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // 이메일 입력 컨트롤러
  final _emailController = TextEditingController();

  // 상태 관리 필드
  bool _isCodeRequested = false; // 버튼 비활성화에 사용 (발급 완료 시)
  bool _isLoading = false;       // 로딩 상태

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 임시 비밀번호 발급 요청 & 성공 시 로그인 화면으로 돌아가기
  Future<void> _handleCodeRequest() async {
    // 1. 이메일 유효성 검사
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('유효한 이메일을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 2. 서버에 임시 비밀번호 발급 요청
      await _authService.requestPasswordResetCode(_emailController.text);
      
      // 3. 요청 성공 시 알림 표시 및 화면 이동
      _showSnackBar('임시 비밀번호 전송 완료. 로그인 화면으로 돌아갑니다.');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 4. 요청 실패 시 에러 메시지 표시
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 공통 SnackBar 표시 유틸리티
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 버튼 스타일 정의
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6AA84F),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
    final disabledButtonStyle = buttonStyle.copyWith(
      backgroundColor: WidgetStateProperty.all(Colors.grey.shade400),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '임시 비밀번호 발급',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 65),

              // 이메일 입력 섹션
              const Text('가입한 이메일 주소를 입력해주세요.', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '이메일',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6AA84F), width: 2.0),
                  ),
                ),
                readOnly: _isCodeRequested, // 발급 요청 후에는 수정 불가
              ),
              const SizedBox(height: 10),
              
              // 발급 버튼
              ElevatedButton(
                onPressed: _isLoading || _isCodeRequested ? null : _handleCodeRequest,
                style: _isLoading || _isCodeRequested ? disabledButtonStyle : buttonStyle,
                child: const Text('발급'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
