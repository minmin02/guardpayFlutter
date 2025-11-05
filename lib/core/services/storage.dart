// storage.dart (새 파일)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,  // ✅ 항상 동일 옵션
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked,
    ),
  );
}
