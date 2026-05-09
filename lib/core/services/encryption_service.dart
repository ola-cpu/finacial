import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';

  static Future<List<int>> getOrCreateEncryptionKey() async {
    final containsKey = await _storage.containsKey(key: _keyName);
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(key));
    }
    final encodedKey = await _storage.read(key: _keyName);
    return base64Url.decode(encodedKey!);
  }
}
