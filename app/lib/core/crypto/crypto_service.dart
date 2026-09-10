/// Abstract interface for encryption/decryption.
/// Swap implementations by changing which class is provided.
abstract class CryptoService {
  /// Encrypts [plainText] and returns a map with 'cipherText' and 'iv'.
  Future<Map<String, String>> encryptText(String plainText, [String? customIvBase64]);

  /// Decrypts [cipherText] using the provided [iv].
  Future<String> decryptText(String cipherText, String iv);

  /// Initializes the crypto service (derives key from user ID or secure storage).
  Future<void> initialize([String? explicitUserId]);

  /// Returns true if the service is ready to encrypt/decrypt.
  bool get isInitialized;
}
