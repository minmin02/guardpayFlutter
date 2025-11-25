import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// 분리된 서비스와 위젯을 임포트합니다.
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/auth_input_field.dart';

// 회원가입 화면
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. 서비스 인스턴스 및 상태 관리
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>(); // 폼 유효성 검사를 위한 키

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _termsAgreed = false;
  bool _isEmailChecked = false; // 이메일 중복 확인 여부
  bool _isLoading = false; // 로딩 상태

  @override
  void initState() {
    super.initState();
    // ✅ 이메일 컨트롤러에 리스너 추가
    _emailController.addListener(_onEmailChanged);
  }

  // ✅ 이메일이 변경되면 중복 확인 상태 초기화
  void _onEmailChanged() {
    if (_isEmailChecked) {
      setState(() { _isEmailChecked = false; });
    }
  }

  // 2. 이메일 중복 확인 핸들러
  Future<void> _handleEmailCheck() async {
    // 이메일 형식 검증
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return;
    }

    // 간단한 이메일 형식 검증
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('올바른 이메일 형식을 입력해주세요.');
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final isAvailable = await _apiService.checkEmailDuplicate(email);
      if (isAvailable) {
        setState(() { _isEmailChecked = true; });
        _showSnackBar('사용 가능한 이메일입니다.');
      }
    } catch (e) {
      setState(() { _isEmailChecked = false; });
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // 3. '가입하기' 버튼 함수 (최종 제출)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return; // 폼 유효성 검사 실패 시 종료
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (!_isEmailChecked) {
      _showSnackBar('이메일 중복 확인을 완료해주세요.');
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

      // 회원가입 성공 시 로그인 화면으로 이동
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }

    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // 4. 카카오 로그인/가입 처리 핸들러
  Future<void> _handleKakaoSignup() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final result = await _authService.signupWithKakao();
      final isNewUser = result['isNewUser'] ?? false;

      if (isNewUser) {
        _showSnackBar('카카오 계정으로 가입을 진행합니다. 추가 정보 입력 화면으로 이동합니다.');
      } else {
        _showSnackBar('카카오 계정으로 로그인되었습니다. 메인 화면으로 이동합니다.');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // 간결한 SnackBar 표시 유틸리티
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 리소스 해제
  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged); // ✅ 리스너 제거
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

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

              // 1. 이메일 입력 및 중복 확인
              const Text('이메일 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: AuthInputField(
                      controller: _emailController,
                      hintText: '이메일',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요.';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return '올바른 이메일 형식을 입력해주세요.';
                        }
                        return null;
                      },
                      // ✅ onChanged 제거
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailChecked
                          ? Colors.grey
                          : const Color(0xFF6AA84F),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                        : Text(
                      _isEmailChecked ? '확인완료' : '중복확인',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isEmailChecked)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '✓ 사용 가능한 이메일입니다',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              // 2. 비밀번호 입력
              const Text('비밀번호 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField(
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
              AuthInputField(
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

              // 3. 닉네임 입력
              const Text('닉네임 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              AuthInputField(
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
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('가입하기', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // 'OR' 구분선
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

              // 카카오로 시작하기 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _handleKakaoSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}