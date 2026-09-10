import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'crypto_service.dart';

/// AES-256-GCM encryption implementation.
/// Keys are stored in Android Keystore via flutter_secure_storage.
class AesCryptoService implements CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();


  encrypt.Key? _key;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    String? storedKey = await _secureStorage.read(
      key: AppConstants.encryptionKeyStorage,
    );

    if (storedKey == null) {
      // Generate a new 256-bit key
      final newKey = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: AppConstants.encryptionKeyStorage,
        value: newKey.base64,
      );
      _key = newKey;
    } else {
      _key = encrypt.Key.fromBase64(storedKey);
    }

    _initialized = true;
  }

  @override
  Future<Map<String, String>> encryptText(String plainText, [String? customIvBase64]) async {
    if (!_initialized || _key == null) {
      await initialize();
    }

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
    if (!_initialized || _key == null) {
      await initialize();
    }

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
