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
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _termsAgreed = false;
  bool _serviceTermsAgreed = false;
  bool _privacyPolicyAgreed = false;
  bool _marketingAgreed = false;

  bool _isEmailChecked = false; // 이메일 중복 확인 여부
  bool _isLoading = false;

  // ========== 약관 전문 ==========
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

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  // 이메일이 변경되면 중복 확인 상태 초기화
  void _onEmailChanged() {
    if (_isEmailChecked) {
      setState(() => _isEmailChecked = false);
    }
  }

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

  // 약관 전체 동의 토글
  void _toggleAllTerms(bool? value) {
    setState(() {
      _termsAgreed = value ?? false;
      _serviceTermsAgreed = value ?? false;
      _privacyPolicyAgreed = value ?? false;
      _marketingAgreed = value ?? false;
    });
  }

  // 개별 약관 체크 시 전체 동의 상태 업데이트
  void _updateAllTermsState() {
    setState(() {
      _termsAgreed = _serviceTermsAgreed && _privacyPolicyAgreed;
    });
  }

  // 2. 이메일 중복 확인 핸들러
  Future<void> _handleEmailCheck() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('올바른 이메일 형식을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isAvailable = await _apiService.checkEmailDuplicate(email);
      if (isAvailable) {
        setState(() => _isEmailChecked = true);
        _showSnackBar('사용 가능한 이메일입니다.');
      }
    } catch (e) {
      setState(() => _isEmailChecked = false);
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 3. '가입하기' 버튼 함수 (최종 제출)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (!_isEmailChecked) {
      _showSnackBar('이메일 중복 확인을 완료해주세요.');
      return;
    }

    if (!_serviceTermsAgreed || !_privacyPolicyAgreed) {
      _showSnackBar('필수 약관에 동의해주세요.');
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

  // 4. 카카오 로그인/가입 처리 핸들러
  Future<void> _handleKakaoSignup() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

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
      if (mounted) {
        setState(() => _isLoading = false);
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
    _emailController.removeListener(_onEmailChanged);
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

              // 4. 약관 동의 (상세)
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
                    // 전체 동의
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAgreed,
                          onChanged: _toggleAllTerms,
                        ),
                        const Text(
                          '약관 전체 동의',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),

                    // 필수 약관 1 - 서비스 이용약관
                    Row(
                      children: [
                        Checkbox(
                          value: _serviceTermsAgreed,
                          onChanged: (v) {
                            setState(() => _serviceTermsAgreed = v ?? false);
                            _updateAllTermsState();
                          },
                        ),
                        const Expanded(
                          child: Text(
                            '(필수) 서비스 이용약관 동의',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPolicyDialog(
                            "서비스 이용약관",
                            termsOfServiceText,
                          ),
                          child: const Text('보기'),
                        ),
                      ],
                    ),

                    // 필수 약관 2 - 개인정보 수집
                    Row(
                      children: [
                        Checkbox(
                          value: _privacyPolicyAgreed,
                          onChanged: (v) {
                            setState(() => _privacyPolicyAgreed = v ?? false);
                            _updateAllTermsState();
                          },
                        ),
                        const Expanded(
                          child: Text(
                            '(필수) 개인정보 수집 및 이용 동의',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPolicyDialog(
                            "개인정보 수집 및 이용",
                            privacyPolicyText,
                          ),
                          child: const Text('보기'),
                        ),
                      ],
                    ),

                    // 선택 약관 - 마케팅
                    Row(
                      children: [
                        Checkbox(
                          value: _marketingAgreed,
                          onChanged: (v) {
                            setState(() => _marketingAgreed = v ?? false);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            '(선택) 마케팅 정보 수신 동의',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPolicyDialog(
                            "마케팅 정보 수신",
                            marketingPolicyText,
                          ),
                          child: const Text('보기'),
                        ),
                      ],
                    ),
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                    : const Text(
                  '가입하기',
                  style: TextStyle(color: Colors.white),
                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}