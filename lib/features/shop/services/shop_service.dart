import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/shop_models.dart';

const String _baseUrl = "http://10.0.2.2:8080/api";

class ShopService {
  final http.Client _client = http.Client();

  // 사용자 프로필 조회 (포인트 로드)
  Future<ProfileModel> getProfile(String token) async {
    final url = Uri.parse('$_baseUrl/members/profile');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return ProfileModel.fromJson(responseBody);
      } else {
        throw Exception('프로필 조회 실패. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류로 프로필 조회 실패: $e');
    }
  }

  // 상품 목록 조회
  Future<List<ProductModel>> getProducts() async {
    final url = Uri.parse('$_baseUrl/shop/products');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> productListJson = responseBody['data'];

        return productListJson.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('상품 목록 조회 실패. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류로 상품 목록 조회 실패: $e');
    }
  }

  // 상품 교환
  Future<ExchangeResponseModel> exchangeProduct(int productId, String token) async {
    final url = Uri.parse('$_baseUrl/shop/exchange/$productId');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return ExchangeResponseModel.fromJson(responseBody['data']);
    } else if (response.statusCode == 400) {
      final message = responseBody['message'] ?? '상품 교환에 실패했습니다.';
      throw Exception(message);
    } else {
      throw Exception('상품 교환 실패. Status Code: ${response.statusCode}');
    }
  }

  // 교환 내역 조회
  Future<List<ExchangeHistoryItemModel>> getExchangeHistory(String token) async {
    final url = Uri.parse('$_baseUrl/shop/history');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> historyListJson = responseBody['data']['exchanges'];

        return historyListJson.map((json) => ExchangeHistoryItemModel.fromJson(json)).toList();
      } else {
        throw Exception('교환 내역 조회 실패. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('교환 내역 조회 중 네트워크 오류: $e');
    }
  }
}