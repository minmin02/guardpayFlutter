import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardpayfront/core/services/storage.dart';
import 'auth_service.dart';
import 'dart:developer';

class ApiService {
  final storage = AppStorage.storage;
  final AuthService _authService = AuthService();
  final String _baseUrl = "http://10.0.2.2:8080";

  // JWT 토큰 타입 추출
  String? _jwtType(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      String norm(String s) =>
          s.replaceAll('-', '+').replaceAll('_', '/').padRight((s.length + 3) ~/ 4 * 4, '=');
      final payload = utf8.decode(base64.decode(norm(parts[1])));
      final obj = jsonDecode(payload) as Map<String, dynamic>;
      return (obj['type'] as String?)?.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  // 토큰 마스킹
  String _mask(String? t) =>
      (t == null || t.length <= 12) ? '***' : '${t.substring(0, 6)}...${t.substring(t.length - 4)}';

  // ✅ 새 access 토큰을 마지막에 덮는 헬퍼
  Map<String, String> _mergeHeadersWithAuth(Map<String, String>? base, String newAccess) {
    final merged = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?base,
    };
    merged['Authorization'] = 'Bearer $newAccess';
    return merged;
  }

  // ✅ 공통 GET
  Future<Map<String, dynamic>?> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      log('>>> [GET] Request to: $url');

      var response = await http.get(
        url,
        headers: _mergeHeadersWithAuth(headers, (await storage.read(key: 'accessToken')) ?? ''),
      );

      if (response.statusCode == 401) {
        log('>>> [GET] Got 401 → try refresh');
        final refresh = await storage.read(key: 'refreshToken');
        if (refresh != null && await _authService.checkAndRefreshTokens(refresh)) {
          final newAccess = await storage.read(key: 'accessToken');
          log('>>> [GET] Token refreshed, retrying with new access');
          response = await http.get(url, headers: _mergeHeadersWithAuth(headers, newAccess!));
        }
      }

      final body = utf8.decode(response.bodyBytes);
      log('>>> [GET] Status: ${response.statusCode}, Body: $body');
      return json.decode(body);
    } catch (e) {
      log('>>> [GET] Exception: $e');
      return null;
    }
  }

  // ✅ 공통 PUT
  Future<Map<String, dynamic>?> put(String endpoint,
      {Map<String, dynamic>? data, Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      var access = await storage.read(key: 'accessToken');
      var response = await http.put(url,
          headers: _mergeHeadersWithAuth(headers, access ?? ''),
          body: json.encode(data));

      if (response.statusCode == 401) {
        log('>>> [PUT] Got 401 → try refresh');
        final refresh = await storage.read(key: 'refreshToken');
        if (refresh != null && await _authService.checkAndRefreshTokens(refresh)) {
          final newAccess = await storage.read(key: 'accessToken');
          log('>>> [PUT] Token refreshed, retrying with new access');
          response = await http.put(url,
              headers: _mergeHeadersWithAuth(headers, newAccess!), body: json.encode(data));
        }
      }

      final body = utf8.decode(response.bodyBytes);
      log('>>> [PUT] Status: ${response.statusCode}, Body: $body');
      return json.decode(body);
    } catch (e) {
      log('>>> [PUT] Exception: $e');
      return null;
    }
  }

  // ✅ 공통 PATCH
  Future<Map<String, dynamic>?> patch(String endpoint,
      {Map<String, dynamic>? data, Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      var access = await storage.read(key: 'accessToken');
      var response = await http.patch(url,
          headers: _mergeHeadersWithAuth(headers, access ?? ''),
          body: json.encode(data));

      if (response.statusCode == 401) {
        log('>>> [PATCH] Got 401 → try refresh');
        final refresh = await storage.read(key: 'refreshToken');
        if (refresh != null && await _authService.checkAndRefreshTokens(refresh)) {
          final newAccess = await storage.read(key: 'accessToken');
          log('>>> [PATCH] Token refreshed, retrying with new access');
          response = await http.patch(url,
              headers: _mergeHeadersWithAuth(headers, newAccess!), body: json.encode(data));
        }
      }

      final body = utf8.decode(response.bodyBytes);
      log('>>> [PATCH] Status: ${response.statusCode}, Body: $body');
      return json.decode(body);
    } catch (e) {
      log('>>> [PATCH] Exception: $e');
      return null;
    }
  }

  // ✅ Chat용 (기존 그대로 유지)
  Future<http.Response> _executeApiCall(String token, String message) async {
    final uri = Uri.parse('$_baseUrl/api/chat/financial-advice');
    final body = jsonEncode({'prompt': message});
    log('>> [CHAT:req] POST $uri');
    log('>> [CHAT:req] Authorization: Bearer ${_mask(token)}');
    final res = await http.post(uri,
        headers: _mergeHeadersWithAuth({'Authorization': 'Bearer $token'}, token), body: body);
    log('>> [CHAT:res] status=${res.statusCode}');
    return res;
  }

  Future<String> sendChatMessage(String message) async {
    log('>>> [API] enter sendChatMessage');
    String? access = await storage.read(key: 'accessToken');
    String? refresh = await storage.read(key: 'refreshToken');

    if (access == null && refresh != null) {
      final ok = await _authService.checkAndRefreshTokens(refresh);
      if (ok) access = await storage.read(key: 'accessToken');
    }

    if (access == null) return "로그인이 필요합니다.";

    var res = await _executeApiCall(access, message);
    if (res.statusCode == 401 && refresh != null) {
      if (await _authService.checkAndRefreshTokens(refresh)) {
        final newAccess = await storage.read(key: 'accessToken');
        res = await _executeApiCall(newAccess!, message);
      }
    }

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode == 200) {
      final map = jsonDecode(body);
      return map['text'] ?? "AI 응답 파싱 실패";
    }
    return "오류: ${res.statusCode} / $body";
  }
}
