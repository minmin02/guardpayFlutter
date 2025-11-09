import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardpayfront/features/video/models/video_model.dart';

class VideoService {
  final String baseUrl = 'http://10.0.2.2:8080/api/videos';

  /// ✅ [1] 영상 카테고리 목록 불러오기
  Future<List<VideoCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((v) => VideoCategory.fromJson(v)).toList();
    } else {
      throw Exception('카테고리 불러오기 실패 (${response.statusCode})');
    }
  }

  /// ✅ [2] 카테고리별 영상 목록
  Future<List<PreventionVideo>> fetchVideosByCategory(int categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((v) => PreventionVideo.fromJson(v)).toList();
    } else {
      throw Exception('카테고리별 영상 조회 실패 (${response.statusCode})');
    }
  }

  /// ✅ [3] 영상 상세 조회
  Future<PreventionVideo> fetchVideoDetail(int videoId) async {
    final response = await http.get(Uri.parse('$baseUrl/$videoId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
      return PreventionVideo.fromJson(json);
    } else {
      throw Exception('영상 상세 조회 실패 (${response.statusCode})');
    }
  }

  /// ✅ [4] 조회수 증가
  Future<void> increaseViewCount(int videoId) async {
    final response = await http.post(Uri.parse('$baseUrl/$videoId/view'));
    if (response.statusCode != 200) {
      throw Exception('조회수 증가 실패 (${response.statusCode})');
    }
  }
}
