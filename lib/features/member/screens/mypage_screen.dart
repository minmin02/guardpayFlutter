import 'package:flutter/material.dart';
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart';
import 'package:image_picker/image_picker.dart';
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

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  String? profileImageUrl;
  File? _selectedImage;
  double fontSize = 16.0;
  bool isLoading = true;
  bool isEditing = false; // 수정 모드 여부
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

// 🔹 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      final token = await storage.read(key: 'accessToken');

      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // API 호출
      final response = await _api.get(
        '/api/v1/users/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];
        setState(() {
          // ✅ name 필드 사용
          _nicknameController.text = data['name'] ?? 'OOO';
          profileImageUrl = data['profileImage'];

          // ✅ fontSize 문자열 → 숫자 매핑
          if (data['settings'] != null && data['settings']['fontSize'] != null) {
            final fontSizeSetting = data['settings']['fontSize'];

            if (fontSizeSetting is num) {
              fontSize = fontSizeSetting.toDouble();
            } else if (fontSizeSetting is String) {
              switch (fontSizeSetting.toLowerCase()) {
                case 'small':
                  fontSize = 12.0;
                  break;
                case 'medium':
                  fontSize = 16.0;
                  break;
                case 'large':
                  fontSize = 20.0;
                  break;
                default:
                  fontSize = 16.0;
              }
            }
          }

          isLoading = false;
        });
      } else {
        // API 실패 시 기본값
        setState(() {
          _nicknameController.text = "OOO";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ 사용자 정보 로드 실패: $e");
      setState(() {
        _nicknameController.text = "OOO";
        isLoading = false;
      });
    }
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // 비밀번호 확인
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

      // API 호출: PUT /api/v1/users/me
      final Map<String, dynamic> updateData = {
        'name': _nicknameController.text,
      };

      // 비밀번호가 입력된 경우에만 추가
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      // 이미지가 선택된 경우 처리
      if (_selectedImage != null) {
        // TODO: 이미지 업로드 로직 추가 (Base64 또는 Multipart)
        // updateData['profileImage'] = base64Image;
      }

      final response = await _api.put(
        '/api/v1/users/me',
        data: updateData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 성공적으로 수정되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 수정 모드 종료 및 정보 새로고침
          setState(() {
            isEditing = false;
            _passwordController.clear();
            _passwordConfirmController.clear();
            _selectedImage = null;
          });
          _loadUserInfo();
        }
      } else {
        throw Exception(response?['message'] ?? '프로필 수정에 실패했습니다.');
      }
    } catch (e) {
      print("❌ 프로필 수정 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 수정에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

// 🔹 글자 크기 저장 로직
  String _fontSizeToString(double size) {
    if (size <= 13.0) return 'small';
    if (size >= 19.0) return 'large';
    return 'medium';
  }

  Future<void> _saveFontSize(double size) async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) return;

      final fontSizeLabel = _fontSizeToString(size);

      // ✅ 서버에 문자열 전송
      final response = await _api.patch(
        '/api/v1/users/me/settings',
        data: {'fontSize': fontSizeLabel},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response['success'] == true) {
        print("✅ 글자 크기 저장 성공: $fontSizeLabel");
      }
    } catch (e) {
      print("❌ 글자 크기 저장 실패: $e");
    }
  }


  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),

              // 등급 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    '안전송금 새싹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 프로필 이미지
              Center(
                child: GestureDetector(
                  onTap: isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                          image: _selectedImage != null
                              ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                              : profileImageUrl != null
                              ? DecorationImage(
                            image:
                            NetworkImage(profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: _selectedImage == null &&
                            profileImageUrl == null
                            ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 설정 섹션
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ✅ 설정 전체를 흰색 박스로 감싸기
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임
                    if (isEditing)
                      TextFormField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          hintText: '닉네임을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '닉네임을 입력해주세요';
                          }
                          if (value.length < 2) {
                            return '닉네임은 2자 이상이어야 합니다';
                          }
                          return null;
                        },
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '닉네임',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            _nicknameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // 비밀번호
                    if (isEditing)
                      Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '새 비밀번호 (변경 시에만 입력)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 8) {
                                return '비밀번호는 8자 이상이어야 합니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '비밀번호 확인',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (_passwordController.text.isNotEmpty &&
                                  value != _passwordController.text) {
                                return '비밀번호가 일치하지 않습니다';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '비밀번호',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            '••••••••',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 25),

                    // 글자 크기
                    const Text(
                      '글자 크기',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('가', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.green,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: Colors.green,
                              overlayColor: Colors.green.withOpacity(0.2),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: fontSize,
                              min: 12.0,
                              max: 20.0,
                              divisions: 8,
                              onChanged: (value) {
                                setState(() {
                                  fontSize = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const Text('가', style: TextStyle(fontSize: 20)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 포인트 내역 & 쿠폰함
                    _buildMenuButton('포인트 내역', () {
                      Navigator.pushNamed(context, '/point-history');
                    }),
                    const SizedBox(height: 12),
                    _buildMenuButton('내 쿠폰함', () {
                      Navigator.pushNamed(context, '/coupon-list');
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 40),


              // 🔹 수정/저장 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            _passwordController.clear();
                            _passwordConfirmController.clear();
                            _selectedImage = null;
                          });
                          _loadUserInfo(); // 원래 정보로 복구
                        },
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () {
                        if (isEditing) {
                          _updateProfile();
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isUpdating
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        isEditing ? '저장' : '수정',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(selectedIndex: 4),
    );
  }

  Widget _buildMenuButton(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}