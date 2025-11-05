// ApiService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardpayfront/core/services/storage.dart';
import 'auth_service.dart';
import 'dart:developer'; // 👈 print 대신 log를 사용하기 위해 추가 (권장)

class ApiService {
  final storage = AppStorage.storage;
  final AuthService _authService = AuthService();
  // ❗️ 안드로이드 에뮬레이터 기준. 실제 기기 테스트 시 PC의 IP로 변경 필요
  final String _baseUrl = "http://10.0.2.2:8080";

  String? _jwtType(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      String norm(String s) =>
          s.replaceAll('-', '+').replaceAll('_', '/').padRight((s.length + 3) ~/ 4 * 4, '=');
      final payload = utf8.decode(base64.decode(norm(parts[1])));
      final obj = jsonDecode(payload) as Map<String, dynamic>;
      return (obj['type'] as String?)?.toLowerCase(); // "access" | "refresh"
    } catch (_) {
      return null;
    }
  }

  String _mask(String? t) =>
      (t == null || t.length <= 12) ? '***' : '${t.substring(0, 6)}...${t.substring(t.length - 4)}';

  Future<http.Response> _executeApiCall(String token, String message) async {
    final uri = Uri.parse('$_baseUrl/api/chat/financial-advice');
    final body = jsonEncode({'prompt': message});

    log('>> [CHAT:req] POST $uri');
    log('>> [CHAT:req] Authorization: Bearer ${_mask(token)} (type=${_jwtType(token)})');
    log('>> [CHAT:req] Body: $body');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    // ✅ UTF-8 디코딩을 여기서 한 번만 하도록 통일
    final responseBody = utf8.decode(res.bodyBytes);
    log('>> [CHAT:res] status=${res.statusCode}');
    log('>> [CHAT:res] headers=${res.headers}');
    log('>> [CHAT:res] body=$responseBody');

    return res; // response 객체 자체를 반환 (bodyBytes를 포함)
  }

  Future<String> sendChatMessage(String message) async {
    log('>>> [API] enter sendChatMessage: "$message"');

    String? access = await storage.read(key: 'accessToken');
    String? refresh = await storage.read(key: 'refreshToken');

    log('>>> [API] loaded tokens: access=${_mask(access)} type=${access==null?null:_jwtType(access)} '
        '/ refresh=${_mask(refresh)} type=${refresh==null?null:_jwtType(refresh)}');

    // access가 없고 refresh가 있으면 먼저 갱신 시도
    if (access == null && refresh != null) {
      log('>>> [API] access is null, try refresh with refresh=${_mask(refresh)}');
      final ok = await _authService.checkAndRefreshTokens(refresh);
      log('>>> [API] refresh result: $ok');
      if (ok) {
        access = await storage.read(key: 'accessToken');
        log('>>> [API] new access after refresh: ${_mask(access)} type=${access==null?null:_jwtType(access)}');
      }
    }

    if (access == null) {
      log('>>> [API] early return: access still null -> "로그인이 필요합니다."');
      return "로그인이 필요합니다.";
    }

    final aType = _jwtType(access);
    if (aType != null && aType != 'access') {
      log('>>> [API] guard: access.type != access (type=$aType)');
      if (refresh == null) {
        log('>>> [API] no refresh -> deleteAll & return');
        await storage.deleteAll();
        return "세션이 만료되었습니다. 다시 로그인해주세요.";
      }
      final ok = await _authService.checkAndRefreshTokens(refresh);
      log('>>> [API] refresh-by-guard result: $ok');
      if (!ok) {
        await storage.deleteAll();
        return "세션이 만료되었습니다. 다시 로그인해주세요.";
      }
      access = await storage.read(key: 'accessToken');
      log('>>> [API] access after guard-refresh: ${_mask(access)} type=${access==null?null:_jwtType(access)}');
      if (access == null || _jwtType(access) != 'access') {
        await storage.deleteAll();
        return "세션이 만료되었습니다. 다시 로그인해주세요.";
      }
    }

    log('>>> [API] call _executeApiCall with access=${_mask(access)}');
    http.Response response = await _executeApiCall(access, message);

    if (response.statusCode == 401) {
      log('>>> [API] got 401, try refresh & retry');
      final currentRefresh = await storage.read(key: 'refreshToken');
      if (currentRefresh != null) {
        final refreshSuccess = await _authService.checkAndRefreshTokens(currentRefresh);
        log('>>> [API] refresh-on-401 result: $refreshSuccess');
        if (refreshSuccess) {
          final newAccess = await storage.read(key: 'accessToken');
          log('>>> [API] newAccess after 401-refresh: ${_mask(newAccess)} type=${newAccess==null?null:_jwtType(newAccess)}');
          if (newAccess != null && _jwtType(newAccess) == 'access') {
            response = await _executeApiCall(newAccess, message);
          } else {
            await storage.deleteAll();
            return "세션이 만료되었습니다. 다시 로그인해주세요.";
          }
        } else {
          await storage.deleteAll();
          return "세션이 만료되었습니다. 다시 로그인해주세요.";
        }
      } else {
        await storage.delete(key: 'accessToken');
        return "세션이 만료되었습니다. 다시 로그인해주세요.";
      }
    }

    // ✅ 응답 본문을 미리 디코딩
    final String responseBody = utf8.decode(response.bodyBytes);
    log('>>> [API] final status: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        // ✅ [수정] response.bodyBytes 대신 미리 디코딩한 responseBody 사용
        final map = jsonDecode(responseBody) as Map<String, dynamic>;

        // ✅ [수정] 서버가 반환하는 JSON 키인 'text'를 사용합니다.
        final text = map['text'] as String?;

        if (text != null) {
          log('>>> [API] parsed text ok (${text.length} chars)');
          return text;
        } else {
          log('>>> [API] parse error: "text" key is null or missing');
          log('>>> [API] raw response: $responseBody');
          return 'AI 응답 파싱 실패: "text" 키를 찾을 수 없습니다.';
        }

      } catch (e) {
        log('>>> [API] parse error: $e');
        log('>>> [API] raw response: $responseBody');
        return "AI 응답 파싱 실패: $e";
      }
    } else {
      log('>>> [API] non-200: ${response.statusCode} / $responseBody');
      return "오류가 발생했습니다: ${response.statusCode} / $responseBody";
    }
  }
}