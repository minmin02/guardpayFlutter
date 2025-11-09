import 'package:flutter/material.dart';

class VideoCategoryScreen extends StatefulWidget {
  const VideoCategoryScreen({super.key});

  @override
  State<VideoCategoryScreen> createState() => _VideoCategoryScreenState();
}

class _VideoCategoryScreenState extends State<VideoCategoryScreen> {
  // 목업 데이터 (디자인 테스트용)
  final List<Map<String, dynamic>> _mockCategories = [
    {
      'id': 1,
      'name': '보이스피싱',
      'description': '전화를 이용한 금융사기 예방',
      'icon': 'phone_warning',
    },
    {
      'id': 2,
      'name': '스미싱',
      'description': '문자 메시지를 이용한 사기 예방',
      'icon': 'message_warning',
    },
    {
      'id': 3,
      'name': '대출사기',
      'description': '불법 대출 유도 사기 예방',
      'icon': 'money_warning',
    },
    {
      'id': 4,
      'name': '파밍',
      'description': '개인정보 탈취 사기 예방',
      'icon': 'security_warning',
    },
  ];

  IconData getIcon(String iconName) {
    switch (iconName) {
      case 'phone_warning':
        return Icons.phone_in_talk;
      case 'message_warning':
        return Icons.sms_failed;
      case 'money_warning':
        return Icons.attach_money;
      case 'security_warning':
        return Icons.security;
      default:
        return Icons.play_circle_fill;
    }
  }

  Color getColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B), // 빨강 - 보이스피싱
      const Color(0xFF4ECDC4), // 청록 - 스미싱
      const Color(0xFFFFBE0B), // 노랑 - 대출사기
      const Color(0xFF9B59B6), // 보라 - 파밍
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      appBar: AppBar(
        title: const Text(
          '금융사기 예방 영상',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 20.0),
        itemCount: _mockCategories.length,
        itemBuilder: (context, index) {
          final category = _mockCategories[index];
          final color = getColor(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/videoList',
                    arguments: {
                      'categoryId': category['id'],
                      'categoryName': category['name'],
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // 아이콘
                      Container(
                        width: 60,
                        height: 100,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          getIcon(category['icon']),
                          size: 30,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 텍스트
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 화살표
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/*
🔧 실제 API 연결 시 사용할 코드:

import 'package:guardpayfront/features/video/services/video_service.dart';
import 'package:guardpayfront/features/video/models/video_model.dart';

class _VideoCategoryScreenState extends State<VideoCategoryScreen> {
  final VideoService _videoService = VideoService();
  Future<List<VideoCategory>>? _categories;

  @override
  void initState() {
    super.initState();
    _categories = _videoService.fetchCategories();
  }

  // body를 FutureBuilder로 감싸기
}
*/