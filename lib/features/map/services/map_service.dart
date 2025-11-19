import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardpayfront/features/map/models/bank_model.dart';
import 'package:guardpayfront/features/map/models/location_model.dart';

class MapService {
  final storage = const FlutterSecureStorage();

  // ✅ 백엔드 URL 설정
  static const String baseUrl = 'http://10.0.2.2:8080'; // 에뮬레이터용
  // static const String baseUrl = 'http://192.168.x.x:8080'; // 실제 기기용

  /// 주소 검색 (카카오 API를 통한 검색)
  Future<List<LocationModel>> searchAddressList(String query) async {
    try {
      print('📍 주소 검색 요청: $query');

      final response = await http.get(
        Uri.parse('$baseUrl/api/location/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 검색 결과: ${data.length}개');

        return data
            .map((json) => LocationModel.fromJson(json))
            .toList();
      } else {
        print('❌ 주소 검색 실패: ${response.statusCode}');
        print('Response body: ${utf8.decode(response.bodyBytes)}');
        return [];
      }
    } catch (e) {
      print('❌ 주소 검색 에러: $e');
      return [];
    }
  }

  /// 5km 반경 내 은행 검색
  Future<List<BankModel>> searchBanks(
      String bankName,
      double lat,
      double lng,
      ) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');

      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      print('🏦 은행 검색 요청: $bankName at ($lat, $lng)');

      final uri = Uri.parse('$baseUrl/api/banks/nearby').replace(
        queryParameters: {
          'bankName': bankName,
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'radius': '5000', // 5km
        },
      );

      print('📡 Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 은행 검색 결과: ${data.length}개');

        return data
            .map((json) => BankModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        print('❌ 은행 검색 실패: ${response.statusCode}');
        print('Response body: ${utf8.decode(response.bodyBytes)}');
        throw Exception('은행 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 은행 검색 에러: $e');
      rethrow;
    }
  }

  /// 키워드 검색 (선택적)
  Future<List<LocationModel>> searchKeyword(String keyword) async {
    try {
      print('🔍 키워드 검색: $keyword');

      final response = await http.get(
        Uri.parse('$baseUrl/api/location/search/keyword?keyword=${Uri.encodeComponent(keyword)}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data
            .map((json) => LocationModel.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('❌ 키워드 검색 에러: $e');
      return [];
    }
  }
}