import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../supabase/supabase_service.dart';
import 'crypto_service.dart';

/// AES-256-GCM encryption implementation with deterministic user key derivation.
class AesCryptoService implements CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  encrypt.Key? _key;
  String? _activeUserId;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  /// Derives a deterministic 256-bit AES key for the user using SHA-256 KDF.
  /// Ensures that reinstalling the app or logging in on a new device will derive
  /// the exact same key to decrypt remote data.
  static encrypt.Key deriveUserKey(String userId) {
    final bytes = utf8.encode('locky_vault_v1:$userId:secure_app_salt_2026');
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  @override
  Future<void> initialize([String? explicitUserId]) async {
    final userId = explicitUserId ?? SupabaseService.currentUser?.id;

    if (userId != null && userId.isNotEmpty) {
      _key = deriveUserKey(userId);
      _activeUserId = userId;
      await _secureStorage.write(
        key: AppConstants.encryptionKeyStorage,
        value: _key!.base64,
      );
    } else {
      String? storedKey = await _secureStorage.read(
        key: AppConstants.encryptionKeyStorage,
      );

      if (storedKey != null) {
        _key = encrypt.Key.fromBase64(storedKey);
      } else {
        _key = deriveUserKey(AppConstants.defaultLocalUserId);
        await _secureStorage.write(
          key: AppConstants.encryptionKeyStorage,
          value: _key!.base64,
        );
      }
    }

    _initialized = true;
  }

  Future<void> _ensureKeyUpdated() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (!_initialized || _key == null || (currentUserId != null && currentUserId != _activeUserId)) {
      await initialize(currentUserId);
    }
  }

  @override
  Future<Map<String, String>> encryptText(String plainText, [String? customIvBase64]) async {
    await _ensureKeyUpdated();

    final iv = customIvBase64 != null
        ? encrypt.IV.fromBase64(customIvBase64)
        : encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'cipherText': encrypted.base64,
      'iv': iv.base64,
    };
  }

  @override
  Future<String> decryptText(String cipherText, String iv) async {
    await _ensureKeyUpdated();

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
    );

    final decrypted = encrypter.decrypt(
      encrypt.Encrypted.fromBase64(cipherText),
      iv: encrypt.IV.fromBase64(iv),
    );

    return decrypted;
  }
}
