import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart';
import 'package:guardpayfront/features/shop/screens/my_coupon_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final storage = AppStorage.storage;
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String? _accessToken;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  String? profileImageUrl;
  File? _selectedImage;
  int _points = 0;
  String _grade = '주의 필요';
  bool isLoading = true;
  bool isEditing = false;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Map<String, dynamic> _getGradeInfo(String grade) {
    final normalizedGrade = grade.replaceAll('_', '').replaceAll(' ', '');
    const Color commonTextColor = Color(0xFF424242);

    switch (normalizedGrade) {
      case '안전송금마스터':
        return {
          'text': '안전 송금 마스터',
          'textColor': commonTextColor,
          'bgColor': const Color(0xFFE8F5E9),
        };

      case '금융방패단':
        return {
          'text': '금융 방패단',
          'textColor': commonTextColor,
          'bgColor': const Color(0xFFFFFDE7),
        };

      case '초보금융가':
        return {
          'text': '초보 금융가',
          'textColor': commonTextColor,
          'bgColor': const Color(0xFFFFEBEE),
        };

      default:
        return {
          'text': '주의 필요',
          'textColor': commonTextColor,
          'bgColor': const Color(0xFFE3F2FD),
        };
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await storage.read(key: 'accessToken');

      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _accessToken = token;

      final response = await _api.get(
        '/api/members/profile',
        headers: {'Authorization': 'Bearer $token'},
      );

      print("🔍 프로필 응답: $response");

      if (response != null) {
        setState(() {
          _nicknameController.text = response['nickname'] ?? 'OOO';
          _points = response['points'] ?? 0;
          _grade = response['grade'] ?? '주의 필요';

          final rawImageUrl = response['profileImageUrl'];
          if (rawImageUrl != null) {
            profileImageUrl = Platform.isAndroid
                ? rawImageUrl.replaceAll("localhost", "10.0.2.2")
                : rawImageUrl;
          } else {
            profileImageUrl = null;
          }

          isLoading = false;
        });
      } else {
        setState(() {
          _nicknameController.text = "OOO";
          _points = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ 사용자 정보 로드 실패: $e");
      setState(() {
        _nicknameController.text = "OOO";
        _points = 0;
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.orange),
                ),
                title: const Text('테스트 이미지 사용'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final ByteData data = await rootBundle.load('assets/images/TestProfile.jpg');
                    final buffer = data.buffer;
                    final tempDir = await getTemporaryDirectory();
                    final tempFile = File('${tempDir.path}/test_profile.jpg');
                    await tempFile.writeAsBytes(
                      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
                    );

                    setState(() {
                      _selectedImage = tempFile;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('테스트 이미지가 선택되었습니다.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  } catch (e) {
                    print('❌ 테스트 이미지 로드 실패: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => isUpdating = true);

    try {
      final token = await storage.read(key: 'accessToken');

      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final Map<String, dynamic> updateData = {
        'nickname': _nicknameController.text,
      };

      if (_passwordController.text.isNotEmpty) {
        updateData['currentPassword'] = _currentPasswordController.text;
        updateData['password'] = _passwordController.text;
      }

      final response = await _api.put(
        '/api/members/profile',
        data: updateData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null && _selectedImage != null) {
        await _api.uploadImage(
          '/api/members/profile/image',
          _selectedImage!,
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isEditing = false;
          _passwordController.clear();
          _passwordConfirmController.clear();
          _currentPasswordController.clear();
        });
        _loadUserInfo();
      }
    } catch (e) {
      print("❌ 프로필 수정 실패: $e");
    } finally {
      setState(() => isUpdating = false);
    }
  }

  // 로그아웃
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 저장된 토큰 삭제
        await storage.delete(key: 'accessToken');
        await storage.delete(key: 'refreshToken');

        if (mounted) {
          // 로그인 화면으로 이동 (뒤로가기 불가)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
                (route) => false,
          );
        }
      } catch (e) {
        print('❌ 로그아웃 실패: $e');
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradeInfo = _getGradeInfo(_grade);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 프로필 헤더 영역
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    // 프로필 이미지
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 2,
                            ),
                            image: _selectedImage != null
                                ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                                : profileImageUrl != null
                                ? DecorationImage(
                              image: NetworkImage(
                                profileImageUrl!,
                                headers: {
                                  'Authorization': 'Bearer $_accessToken'
                                },
                              ),
                              fit: BoxFit.cover,
                            )
                                : null,
                            color: Colors.grey[100],
                          ),
                          child: _selectedImage == null && profileImageUrl == null
                              ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                              : null,
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 닉네임
                    Text(
                      _nicknameController.text,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 등급 배지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradeInfo['bgColor'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row( // Row 추가
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 16, // 배지에 맞게 크기 조정
                            color: gradeInfo['textColor'],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            gradeInfo['text'], // 등급별 텍스트
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: gradeInfo['textColor'], // 등급별 글자색
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 포인트 카드
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내 포인트',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'My Points',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_points',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 계정 정보 섹션
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Text(
                        '계정 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey[200]),

                    // 닉네임
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: isEditing
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '닉네임',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nicknameController,
                            decoration: InputDecoration(
                              hintText: '닉네임을 입력하세요',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '닉네임',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _nicknameController.text,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey[200]),

                    // 비밀번호
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: isEditing
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '비밀번호 변경',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '현재 비밀번호',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '새 비밀번호',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '새 비밀번호 확인',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '비밀번호',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '••••••••',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 메뉴 섹션
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildMenuItem(
                      icon: Icons.card_giftcard,
                      title: '내 쿠폰함',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyCouponScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: '로그아웃',
                      onTap: _logout,
                      isLogout: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 버튼 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isEditing
                    ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            _passwordController.clear();
                            _passwordConfirmController.clear();
                            _currentPasswordController.clear();
                          });
                          _loadUserInfo();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text(
                    '프로필 수정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 4),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLogout ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: isLogout ? Colors.red : Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Colors.red : Colors.black87,
                ),
              ),
            ),
            if (!isLogout)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}