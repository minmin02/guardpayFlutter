import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_models.dart';

class TransferService {
  // 💡 에뮬레이터용 주소: http://10.0.2.2:8080/api/v1
  final String _baseUrl = "http://10.0.2.2:8080/api";

  // [응답 처리기]
  dynamic _handleResponse(http.Response response, String endpointName) {
    String decodedBody = utf8.decode(response.bodyBytes);
    print("📥 [$endpointName] Status: ${response.statusCode}");
    print("📥 [$endpointName] Body: $decodedBody");

    final dynamic body;
    try {
      body = json.decode(decodedBody);
    } catch (e) {
      throw Exception('JSON 파싱 실패: $decodedBody');
    }

    if (response.statusCode == 200) {
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } else {
      throw Exception('서버 에러 (${response.statusCode}): $decodedBody');
    }
  }

  Map<String, String> _authHeaders(String accessToken) {
    String cleanToken = accessToken.startsWith('Bearer ')
        ? accessToken.substring(7)
        : accessToken;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $cleanToken',
    };
  }

  // 1. 내 계좌 정보 조회
  Future<MyAccount> getMyAccount(String accessToken) async {
    try {
      print("🚀 [내 계좌 조회] 요청 시작...");
      final url = Uri.parse('$_baseUrl/members/profile');

      final response = await http.get(
        url,
        headers: _authHeaders(accessToken),
      );

      final data = _handleResponse(response, "내 계좌 조회");
      print("✅ [내 계좌 조회] 데이터 파싱 전: $data");

      // [수정] 데이터가 Map이 아니라 숫자(int)로 왔을 때 처리
      if (data is int) {
        print("⚠️ 데이터가 숫자로 왔습니다. 객체로 변환합니다.");
        return MyAccount(
          myId: 'unknown',
          balance: data,
          accountName: 'GuardPay 포인트',
          currency: 'KRW',
        );
      }

      // 정상적인 Map 형태일 때 파싱
      final account = MyAccount.fromJson(data);
      print("✅ [내 계좌 조회] 파싱 성공! 잔액: ${account.balance}");
      return account;

    } catch (e) {
      print('❌ [치명적 에러] 내 계좌 조회 실패: $e');
      throw Exception("데이터 불러오기 실패: $e");
    }
  }

  // 2. 송금 대상 목록 조회
  Future<List<Beneficiary>> getBeneficiaries(String accessToken) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/beneficiaries/random');
      final response = await http.get(url, headers: _authHeaders(accessToken));
      final dynamic data = _handleResponse(response, "송금 대상 조회");

      List<dynamic> list = data is List ? data : [];
      return list.map((json) => Beneficiary.fromJson(json)).toList();
    } catch (e) {
      print('❌ 송금 대상 조회 실패: $e');
      rethrow;
    }
  }

  // 3. 송금하기
  Future<TransferResult> postTransfer({
    required String accessToken,
    required int toBeneficiaryId,
    required int amount,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/beneficiaries/$toBeneficiaryId/transfer');
      final response = await http.post(
        url,
        headers: _authHeaders(accessToken),
        body: json.encode({'amount': amount}),
      );

      final data = _handleResponse(response, "송금 요청");
      return TransferResult.fromJson(data);
    } catch (e) {
      print('❌ 송금 실패: $e');
      rethrow;
    }
  }
}