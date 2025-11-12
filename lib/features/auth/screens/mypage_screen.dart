import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ rootBundle 사용을 위해 추가
import 'package:guardpayfront/core/services/storage.dart';
import 'package:guardpayfront/features/auth/services/api_service.dart';
import 'package:guardpayfront/features/auth/widgets/bottom_nav.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // ✅ 임시 디렉토리 사용을 위해 추가
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
  final TextEditingController _currentPasswordController = TextEditingController(); // ✅ 추가
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  String? profileImageUrl;
  File? _selectedImage;
  double fontSize = 16.0;
  bool isLoading = true;
  bool isEditing = false;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 🔹 사용자 정보 로드 - GET /api/members/profile
  Future<void> _loadUserInfo() async {
    try {
      final token = await storage.read(key: 'accessToken');

      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _accessToken = token;
      });
      final response = await _api.get(
        '/api/members/profile',
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🔍 응답 데이터: $response'); // 디버깅용

      if (response != null) {
        // ✅ 서버가 MemberInfoResponse를 직접 반환하므로 response 자체를 사용
        setState(() {
          _nicknameController.text = response['nickname'] ?? 'OOO';
          String? rawImageUrl = response['profileImageUrl']; // 1. 원본 URL 받기

          if (rawImageUrl != null) {
            // 2. 안드로이드 플랫폼인지 확인 (import 'dart:io'; 필요)
            if (Platform.isAndroid) {
              // 3. 'localhost'를 '10.0.2.2'로 변경
              profileImageUrl = rawImageUrl.replaceAll('localhost', '10.0.2.2');
            } else {
              profileImageUrl = rawImageUrl; // (참고: iOS 시뮬레이터는 localhost로 동작)
            }
          } else {
            profileImageUrl = null;
          }


          isLoading = false;
        });
      } else {
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
            // ✅ 테스트용 이미지 선택 옵션 추가
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('테스트 이미지 사용'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  // assets 이미지를 임시 파일로 복사
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('테스트 이미지 로드 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 프로필 수정 - PUT /api/members/profile
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

      // ✅ 1. 닉네임과 비밀번호 수정
      final Map<String, dynamic> updateData = {
        'nickname': _nicknameController.text,
      };

      // 비밀번호 변경 시 현재 비밀번호와 새 비밀번호 모두 필요
      if (_passwordController.text.isNotEmpty) {
        updateData['currentPassword'] = _currentPasswordController.text;
        updateData['password'] = _passwordController.text;
      }

      print('🔍 수정 요청 데이터: $updateData'); // 디버깅용

      final response = await _api.put(
        '/api/members/profile',
        data: updateData,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🔍 수정 응답: $response'); // 디버깅용

      if (response != null) {
        // ✅ 2. 이미지가 실제로 선택된 경우에만 업로드
        if (_selectedImage != null && _selectedImage!.existsSync()) {
          print('🔍 이미지 업로드 시작: ${_selectedImage!.path}'); // 디버깅용

          try {
            final imageResponse = await _api.uploadImage(
              '/api/members/profile/image',
              _selectedImage!,
              headers: {'Authorization': 'Bearer $token'},
            );

            print('🔍 이미지 업로드 응답: $imageResponse'); // 디버깅용

            if (imageResponse == null) {
              // 이미지 업로드 실패해도 프로필 수정은 성공했으므로 경고만 표시
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('프로필은 수정되었지만 이미지 업로드에 실패했습니다.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            print('❌ 이미지 업로드 예외: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('프로필은 수정되었지만 이미지 업로드에 실패했습니다.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
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
            _selectedImage = null;
          });
          _loadUserInfo();
        }
      } else {
        throw Exception('프로필 수정에 실패했습니다.');
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

  // 🔹 프로필 이미지 삭제 - DELETE /api/members/profile/image
  Future<void> _deleteProfileImage() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) return;

      final success = await _api.delete(
        '/api/members/profile/image',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (success) {
        setState(() {
          profileImageUrl = null;
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ 프로필 이미지 삭제 실패: $e");
    }
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
                  onLongPress: isEditing && (profileImageUrl != null || _selectedImage != null)
                      ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('프로필 이미지 삭제'),
                        content: const Text('프로필 이미지를 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteProfileImage();
                            },
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                  }
                      : null,
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
                              : profileImageUrl != null && _accessToken != null // ✅ 토큰 null 체크
                              ? DecorationImage(
                            // ⬇️ 여기를 수정합니다 ⬇️
                            image: NetworkImage(
                              profileImageUrl!,
                              headers: {
                                'Authorization': 'Bearer $_accessToken'
                              },
                            ),
                            // ⬆️ 여기까지 수정 ⬆️
                            fit: BoxFit.cover,
                          )
                              : null, // 토큰이나 URL이 없으면 null
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
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
                            style: TextStyle(
                                fontSize: 14, color: Colors.black87),
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
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '현재 비밀번호',
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
                                  (value == null || value.isEmpty)) {
                                return '비밀번호를 변경하려면 현재 비밀번호를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
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
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 8) {
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
                              hintText: '새 비밀번호 확인',
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
                            style: TextStyle(
                                fontSize: 14, color: Colors.black87),
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

                    const SizedBox(height: 20),

                    // 포인트 내역 & 쿠폰함
                    _buildMenuButton('포인트 내역', () {
                      // Navigator.pushNamed(context, '/point-history');
                    }),
                    const SizedBox(height: 12),
                    _buildMenuButton('내 쿠폰함', () {
                      // Navigator.pushNamed(context, '/coupon-list');
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 수정/저장/취소 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isEditing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            _passwordController.clear();
                            _passwordConfirmController.clear();
                            _selectedImage = null;
                          });
                          _loadUserInfo();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 저장 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          '저장',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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