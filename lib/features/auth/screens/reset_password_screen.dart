import 'package:flutter/material.dart';

// 1. 필요한 서비스 및 위젯을 임포트합니다.
import '../services/auth_service.dart'; // AuthService 사용
import '../widgets/auth_input_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // 2. 서비스 인스턴스 및 상태 변수를 SignupScreen과 유사하게 구성합니다.
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isCodeRequested = false; // 인증 코드가 요청되었는가?
  bool _isCodeVerified = false;  // 인증 코드가 확인되었는가?
  bool _isLoading = false;       // 로딩 상태

  // 서버에서 받은 정답 인증코드를 저장할 변수
  String _correctCode = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 3. 인증 코드 요청 핸들러
  Future<void> _handleCodeRequest() async {
    // 간단한 이메일 유효성 검사
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('유효한 이메일을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // AuthService가 정답 코드를 String으로 반환
      final String codeFromServer = await _authService.requestPasswordResetCode(_emailController.text);
      _correctCode = codeFromServer;

      setState(() => _isCodeRequested = true);
      _showSnackBar('인증 코드가 이메일로 전송되었습니다.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _isCodeRequested = true;
        _correctCode = '123456'; // ⬅️ 테스트용 정답 코드를 '123456'으로 지정
      });
      _showSnackBar('임시 테스트 성공 처리 (정답 코드: 123456)');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 4. 인증 코드 확인 핸들러
  Future<void> _handleCodeVerify() async {
    if (_codeController.text.isEmpty) {
      _showSnackBar('인증 코드를 입력해주세요.');
      return;
    }

    // 정답 코드와 로컬에서 비교
    if (_correctCode.isNotEmpty && _correctCode == _codeController.text) {
      setState(() => _isCodeVerified = true);
      _showSnackBar('인증이 완료되었습니다. 새 비밀번호를 입력하세요.');
    } else {
      _showSnackBar('인증 코드가 올바르지 않습니다.');
    }
  }

  // 5. 최종 제출 핸들러 (비밀번호 변경)
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // 폼 유효성 검사 실패 시 종료
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!_isCodeVerified) {
      _showSnackBar('이메일 인증을 먼저 완료해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // AuthService를 통해 비밀번호 재설정
      final message = await _authService.resetPassword(
        email: _emailController.text,
        code: _codeController.text, // 백엔드 API에 따라 코드가 필요할 수 있음
        newPassword: _passwordController.text,
      );
      _showSnackBar(message);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 6. 일관된 SnackBar 표시를 위한 유틸리티 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                '새 비밀번호 만들기',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 65),

              // --- 이메일 입력 섹션 ---
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
                readOnly: _isCodeRequested, // 코드 요청 후에는 수정 불가
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading || _isCodeRequested ? null : _handleCodeRequest,
                style: _isLoading || _isCodeRequested ? disabledButtonStyle : buttonStyle,
                child: const Text('인증코드 받기'),
              ),

              // --- 인증코드 입력 섹션 (코드 요청 후에만 보임) ---
              if (_isCodeRequested) ...[
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '인증코드',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6AA84F), width: 2.0),
                          ),
                        ),
                        readOnly: _isCodeVerified, // 인증 완료 후에는 수정 불가
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading || _isCodeVerified ? null : _handleCodeVerify,
                      style: _isLoading || _isCodeVerified ? disabledButtonStyle : buttonStyle,
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ],

              // --- 새 비밀번호 입력 섹션 (인증 완료 후에만 보임) ---
              if (_isCodeVerified) ...[
                const SizedBox(height: 50),
                const Text('비밀번호 재설정', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 10),
                AuthInputField(
                  controller: _passwordController,
                  hintText: '새 비밀번호',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AuthInputField(
                  controller: _passwordConfirmController,
                  hintText: '새 비밀번호 재입력',
                  isPassword: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: buttonStyle,
                  child: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('확인'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

