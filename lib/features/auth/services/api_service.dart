// ApiService.dart
import 'dart:convert';
import 'dart:io'; // ✅ File 타입 사용을 위해 추가
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser; // ✅ MediaType 사용을 위해 추가
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

  // ✅ 공통 HTTP 요청 메서드 - GET
  Future<Map<String, dynamic>?> get(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      log('>> [GET] $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      );

      final responseBody = utf8.decode(response.bodyBytes);
      log('>> [GET:res] status=${response.statusCode}');
      log('>> [GET:res] body=$responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        log('>> [GET:error] ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('>> [GET:exception] $e');
      return null;
    }
  }

  // ✅ 공통 HTTP 요청 메서드 - PUT
  Future<Map<String, dynamic>?> put(
      String endpoint, {
        Map<String, dynamic>? data,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = data != null ? jsonEncode(data) : null;

      log('>> [PUT] $uri');
      log('>> [PUT:body] $body');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
        body: body,
      );

      final responseBody = utf8.decode(response.bodyBytes);
      log('>> [PUT:res] status=${response.statusCode}');
      log('>> [PUT:res] body=$responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        log('>> [PUT:error] ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('>> [PUT:exception] $e');
      return null;
    }
  }

  // ✅ 공통 HTTP 요청 메서드 - PATCH
  Future<Map<String, dynamic>?> patch(
      String endpoint, {
        Map<String, dynamic>? data,
        Map<String, String>? headers,
      }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = data != null ? jsonEncode(data) : null;

      log('>> [PATCH] $uri');
      log('>> [PATCH:body] $body');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
        body: body,
      );

      final responseBody = utf8.decode(response.bodyBytes);
      log('>> [PATCH:res] status=${response.statusCode}');
      log('>> [PATCH:res] body=$responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        log('>> [PATCH:error] ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('>> [PATCH:exception] $e');
      return null;
    }
  }

  // ✅ Multipart 이미지 업로드 메서드 (MIME 타입 명시)
  Future<Map<String, dynamic>?> uploadImage(
      String endpoint,
      File imageFile, {
        Map<String, String>? headers,
      }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      log('>> [MULTIPART] $uri');

      var request = http.MultipartRequest('PUT', uri);

      // 헤더 추가
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // ✅ 파일 확장자에 따라 MIME 타입 결정
      String mimeType = 'image/jpeg'; // 기본값
      String fileName = imageFile.path.split('/').last.toLowerCase();

      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      log('>> [MULTIPART:mimeType] $mimeType');

      // ✅ 이미지 파일 추가 (MIME 타입 명시)
      var multipartFile = http.MultipartFile.fromBytes(
        'profileImage',
        await imageFile.readAsBytes(),
        filename: 'profile.${fileName.split('.').last}',
        contentType: http_parser.MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      log('>> [MULTIPART:file] ${imageFile.path}');
      log('>> [MULTIPART:contentType] ${multipartFile.contentType}');

      // 요청 전송
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseBody = utf8.decode(response.bodyBytes);
      log('>> [MULTIPART:res] status=${response.statusCode}');
      log('>> [MULTIPART:res] body=$responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        log('>> [MULTIPART:error] ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('>> [MULTIPART:exception] $e');
      return null;
    }
  }

  // ✅ DELETE 메서드
  Future<bool> delete(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      log('>> [DELETE] $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      );

      log('>> [DELETE:res] status=${response.statusCode}');

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      log('>> [DELETE:exception] $e');
      return false;
    }
  }
  Future<String?> getMyGrade() async {
    final token = await storage.read(key: 'accessToken');
    if (token == null) return null;

    // 백엔드 경로 확인 필수! (예: /members/me/grade 인지 /api/members/me/grade 인지)
    final result = await get(
      '/api/members/me/grade',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (result != null && result.containsKey('grade')) {
      return result['grade'] as String;
    }
    return null;
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

  // ✅ [추가] 이메일 중복 확인 (GET 요청)
  Future<bool> checkEmailDuplicate(String email) async {
    try {
      // 백엔드 경로: /api/members/check-email?email=user@test.com
      final uri = Uri.parse('$_baseUrl/api/auth/check-email?email=$email');
      log('>> [CheckEmail] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // 응답 디코딩 (한글 깨짐 방지)
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(responseBody);
      log('>> [CheckEmail:res] status=${response.statusCode}, msg=${jsonResponse['message']}');

      if (response.statusCode == 200) {
        return true; // 사용 가능
      } else if (response.statusCode == 409) {
        // 백엔드에서 409(CONFLICT)를 보냈으므로 중복된 이메일임
        throw Exception(jsonResponse['message'] ?? "이미 사용 중인 이메일입니다.");
      } else {
        throw Exception("중복 확인 실패: ${response.statusCode}");
      }
    } catch (e) {
      log('>> [CheckEmail:exception] $e');
      rethrow; // UI에서 에러 메시지를 띄우기 위해 예외 던짐
    }
  }


}