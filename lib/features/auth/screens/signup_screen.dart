import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// 분리된 서비스와 위젯 임포트
import '../services/auth_service.dart';
import '../widgets/email_auth_section.dart';
import '../widgets/auth_input_field.dart';

// 회원가입 화면
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 서비스 및 폼 관리
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _termsAgreed = false;
  bool _isCodeRequested = false;
  bool _isCodeVerified = false;
  bool _isLoading = false;

  // ========== 약관 전문(코드 내 직접 포함) ==========
  final String termsOfServiceText = """
[서비스 이용약관]

1. 본 서비스는 회원에게 다양한 기능을 제공합니다.
2. 회원은 서비스 이용 시 관련 법령을 준수해야 합니다.
3. 회사는 안전하고 안정적인 서비스 제공을 위해 노력합니다.
4. 기타 자세한 내용은 본 약관에 따릅니다.
""";

  final String privacyPolicyText = """
[개인정보 수집 및 이용 안내]

1. 수집 항목: 이메일, 비밀번호, 닉네임
2. 이용 목적: 회원가입, 본인확인, 서비스 운영 및 고객 상담
3. 보관기간: 회원 탈퇴 시까지
""";

  final String marketingPolicyText = """
[마케팅 정보 수신 동의]

1. 이벤트, 혜택, 광고 정보를 제공할 수 있습니다.
2. 수신 여부는 언제든지 설정에서 변경할 수 있습니다.
""";

  // 약관 팝업
  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  // 인증코드 요청
  Future<void> _handleCodeRequest() async {
    setState(() => _isLoading = true);
    try {
      await _authService.requestAuthCode(_emailController.text);
      setState(() {
        _isCodeRequested = true;
        _authCodeController.clear();
      });
      _showSnackBar('인증 코드가 이메일로 전송되었습니다.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 인증코드 확인
  Future<void> _handleCodeVerify() async {
    setState(() => _isLoading = true);
    try {
      await _authService.verifyAuthCode(_emailController.text, _authCodeController.text);
      setState(() => _isCodeVerified = true);
      _showSnackBar('이메일 인증이 완료되었습니다.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 가입 제출
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isLoading = true);
    try {
      final message = await _authService.signup(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      );

      _showSnackBar(message);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 카카오 로그인
  Future<void> _handleKakaoSignup() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signupWithKakao();
      final isNewUser = result['isNewUser'] ?? false;

      if (isNewUser) {
        _showSnackBar('카카오 계정으로 가입합니다. 추가 정보 입력 화면으로 이동합니다.');
      } else {
        _showSnackBar('카카오 계정으로 로그인되었습니다.');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // SnackBar
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // ================== UI ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로고
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

              // 이메일 인증 구역
              EmailAuthSection(
                emailController: _emailController,
                codeController: _authCodeController,
                isCodeRequested: _isCodeRequested,
                isCodeVerified: _isCodeVerified,
                onCodeRequest: _handleCodeRequest,
                onCodeVerify: _handleCodeVerify,
              ),
              const SizedBox(height: 15),

              // 비밀번호
              const Text('비밀번호 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField(
                controller: _passwordController,
                hintText: '비밀번호',
                isPassword: true,
                validator: (v) => (v == null || v.length < 8) ? '비밀번호는 8자 이상이어야 합니다.' : null,
              ),
              const SizedBox(height: 10),
              AuthInputField(
                controller: _passwordConfirmController,
                hintText: '비밀번호 재입력',
                isPassword: true,
                validator: (v) => (v != _passwordController.text) ? '비밀번호가 일치하지 않습니다.' : null,
              ),
              const SizedBox(height: 15),

              // 닉네임
              const Text('닉네임 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField(
                controller: _nicknameController,
                hintText: '닉네임',
                validator: (v) => (v == null || v.isEmpty) ? '닉네임을 입력해주세요.' : null,
              ),
              const SizedBox(height: 25),

              // ================= 약관 동의 =================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAgreed,
                          onChanged: (v) =>
                              setState(() => _termsAgreed = v ?? false),
                        ),
                        const Text(
                          '약관 전체 동의',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),

                    // 필수 약관 1
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(child: Text('(필수) 서비스 이용약관 동의')),
                        TextButton(
                          onPressed: () => _showPolicyDialog("서비스 이용약관", termsOfServiceText),
                          child: const Text('보기'),
                        ),
                      ],
                    ),

                    // 필수 약관 2
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(child: Text('(필수) 개인정보 수집 및 이용 동의')),
                        TextButton(
                          onPressed: () => _showPolicyDialog("개인정보 수집 및 이용", privacyPolicyText),
                          child: const Text('보기'),
                        ),
                      ],
                    ),

                    // 선택 약관
                    Row(
                      children: [
                        Icon(
                          _termsAgreed ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _termsAgreed ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(child: Text('(선택) 마케팅 정보 수신 동의')),
                        TextButton(
                          onPressed: () => _showPolicyDialog("마케팅 정보 수신", marketingPolicyText),
                          child: const Text('보기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 가입 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6AA84F),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('가입하기',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              // OR
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 20),

              // 카카오 시작하기
              ElevatedButton(
                onPressed: _isLoading ? null : _handleKakaoSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '카카오로 시작하기',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
