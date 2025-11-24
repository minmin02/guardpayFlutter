import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_models.dart';

class TransferService {
  // 💡 에뮬레이터용 주소: http://10.0.2.2:8080/api/v1
  final String _baseUrl = "http://10.0.2.2:8080/api/v1";

  // [개선된 응답 처리기] 성공/실패 및 다양한 에러 메시지 포맷 대응
  dynamic _handleResponse(http.Response response) {
    // 1. 디버깅용 로그 출력 (서버 응답 확인용)
    String decodedBody = utf8.decode(response.bodyBytes);
    print("📥 [API] Status: ${response.statusCode}");
    print("📥 [API] Body: $decodedBody");

    final dynamic body;
    try {
      body = json.decode(decodedBody);
    } catch (e) {
      throw Exception('서버 응답이 JSON 형식이 아닙니다. (${response.statusCode})');
    }

    // 2. 성공 (200 OK) 처리
    if (response.statusCode == 200) {
      // 백엔드가 { "status": 200, "data": ... } 형태로 감싸서 줄 때
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      // 백엔드가 껍데기 없이 바로 데이터를 줄 때
      return body;
    }

    // 3. 실패 (400 Bad Request, 500 Error 등) 처리
    else {
      String errorMessage = '알 수 없는 오류가 발생했습니다.';

      // 에러 메시지 추출 시도 ('message' 또는 'error' 필드)
      if (body is Map) {
        errorMessage = body['message'] ?? body['error'] ?? errorMessage;
      } else if (body is String) {
        errorMessage = body;
      }

      print("🚨 [API Error] $errorMessage");
      throw Exception(errorMessage);
    }
  }

  // [안전한 인증 헤더 생성기]
  Map<String, String> _authHeaders(String accessToken) {
    // Bearer 중복 방지 및 공백 제거
    String cleanToken = accessToken;
    if (accessToken.startsWith('Bearer ')) {
      cleanToken = accessToken.substring(7);
    }
    cleanToken = cleanToken.trim();

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $cleanToken',
    };
  }

  // ------------------------------------------------------------------------

// 1. 내 계좌 정보 조회 (API 실패 시 더미 데이터 반환하도록 수정)
  Future<MyAccount> getMyAccount(String accessToken) async {
    try {
      // 1. API 호출 시도
      final url = Uri.parse('$_baseUrl/users/me/points');
      final response = await http.get(
        url,
        headers: _authHeaders(accessToken),
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return MyAccount.fromJson(data);
      } else {
        // 2. 404 등 에러 발생 시 로그 출력 후 예외 발생시켜서 catch로 보냄
        print("⚠️ [API Error] 내 포인트 조회 실패 (Status: ${response.statusCode})");
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      // 3. [중요] 에러가 나도 앱이 멈추지 않게 '임시 데이터'를 반환
      print('❌ 내 계좌 조회 에러 발생: $e');
      print('👉 임시 데이터를 사용하여 화면을 표시합니다.');

      // 백엔드 API가 고쳐질 때까지 사용할 임시 데이터
      return MyAccount(
        balance: 5000000, // 임시 잔액 500만원
        accountName: "GuardPay 임시 통장",
        currency: "KRW",
      );
    }
  }

  // 2. 송금 대상 목록 조회 (랜덤 4명)
  Future<List<Beneficiary>> getBeneficiaries(String accessToken) async {
    try {
      final url = Uri.parse('$_baseUrl/beneficiaries/random');

      final response = await http.get(
        url,
        headers: _authHeaders(accessToken),
      );

      final dynamic data = _handleResponse(response);

      // 리스트 데이터 처리
      List<dynamic> list = data is List ? data : [];
      return list.map((json) => Beneficiary.fromJson(json)).toList();
    } catch (e) {
      print('❌ 송금 대상 조회 실패: $e');
      rethrow;
    }
  }

  // 3. 송금하기 (POST)
  Future<TransferResult> postTransfer({
    required String accessToken,
    required int toBeneficiaryId,
    required int amount,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/beneficiaries/$toBeneficiaryId/transfer');

      final response = await http.post(
        url,
        headers: _authHeaders(accessToken),
        body: json.encode({
          'amount': amount,
        }),
      );

      final data = _handleResponse(response);
      return TransferResult.fromJson(data);
    } catch (e) {
      print('❌ 송금 실패: $e');
      rethrow;
    }
  }
}