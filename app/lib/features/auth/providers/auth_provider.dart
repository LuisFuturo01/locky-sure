import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../shared/utils/error_utils.dart';

enum AuthState { unauthenticated, deviceLockRequired, authenticated }

class AuthProvider extends ChangeNotifier {
  final CryptoService cryptoService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _state = AuthState.unauthenticated;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _emailConfirmationPending = false;
  bool get emailConfirmationPending => _emailConfirmationPending;

  String? _pendingEmail;
  String? get pendingEmail => _pendingEmail;

  bool _isPasswordRecoveryActive = false;
  bool get isPasswordRecoveryActive => _isPasswordRecoveryActive;

  bool _isAuthenticatingManual = false;

  String? get currentUserEmail => SupabaseService.currentUser?.email;

  AuthProvider({required this.cryptoService}) {
    checkCurrentSession();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (_isAuthenticatingManual) return;

      if (event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecoveryActive = true;
        _emailConfirmationPending = false;
        notifyListeners();
        return;
      }

      if (session != null) {
        _emailConfirmationPending = false;
        if (_state == AuthState.unauthenticated && !_isPasswordRecoveryActive) {
          _state = AuthState.deviceLockRequired;
          notifyListeners();
        }
      }
    });
  }

  Future<void> checkCurrentSession() async {
    if (SupabaseService.isAuthenticated) {
      _state = AuthState.deviceLockRequired;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isAuthenticatingManual = true;
    _isLoading = true;
    _errorMessage = null;
    _emailConfirmationPending = false;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await cryptoService.initialize(response.user!.id);
        _state = AuthState.authenticated;
        _isLoading = false;
        _isAuthenticatingManual = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    }

    _isAuthenticatingManual = false;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _isAuthenticatingManual = true;
    _isLoading = true;
    _errorMessage = null;
    _emailConfirmationPending = false;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.surething://login-callback',
      );

      if (response.user != null) {
        if (response.session == null) {
          // Email confirmation link sent to email
          _emailConfirmationPending = true;
          _pendingEmail = email;
          _isLoading = false;
          _isAuthenticatingManual = false;
          notifyListeners();
          return false;
        } else {
          // Direct login (confirmation disabled in Supabase)
          await cryptoService.initialize(response.user!.id);
          _state = AuthState.authenticated;
          _isLoading = false;
          _isAuthenticatingManual = false;
          notifyListeners();
          return true;
        }
      }
    } on AuthException catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    }

    _isAuthenticatingManual = false;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> resendVerificationEmail() async {
    if (_pendingEmail == null) return;
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: _pendingEmail!,
        emailRedirectTo: 'io.supabase.surething://login-callback',
      );
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
      notifyListeners();
    }
  }

  void cancelEmailConfirmation() {
    _emailConfirmationPending = false;
    _pendingEmail = null;
    notifyListeners();
  }

  // --- Local PIN Management (Stored locally in secure storage) ---

  Future<String?> getLocalAppPin() async {
    return await _secureStorage.read(key: AppConstants.localAppPinStorage);
  }

  Future<bool> isLocalPinSet() async {
    final pin = await getLocalAppPin();
    return pin != null && pin.trim().isNotEmpty;
  }

  Future<void> setLocalAppPin(String pin) async {
    await _secureStorage.write(
      key: AppConstants.localAppPinStorage,
      value: pin.trim(),
    );
    notifyListeners();
  }

  Future<void> removeLocalAppPin() async {
    await _secureStorage.delete(key: AppConstants.localAppPinStorage);
    notifyListeners();
  }

  Future<bool> authenticateWithLocalPin(String inputPin) async {
    _errorMessage = null;
    final storedPin = await getLocalAppPin();
    if (storedPin != null && storedPin == inputPin.trim()) {
      await cryptoService.initialize();
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'PIN de acceso local incorrecto.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> hasSystemLockScreen() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        final canCheck = await _localAuth.canCheckBiometrics;
        if (!canCheck) return false;
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithDeviceBiometrics() async {
    try {
      bool isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        _errorMessage = 'El dispositivo no soporta autenticación biométrica ni contraseña.';
        notifyListeners();
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _errorMessage = 'Tu celular no tiene huella o contraseña de pantalla configurada.';
        notifyListeners();
        return false;
      }

      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Ingresa tu huella, PIN, rostro o patrón del celular para desbloquear Locky',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN, Pattern, Passcode, Fingerprint & Face
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await cryptoService.initialize();
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
      notifyListeners();
    }
    return false;
  }

  void lockApp() {
    if (_state == AuthState.authenticated) {
      _state = AuthState.deviceLockRequired;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.surething://login-callback',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int retries = 0;
    while (retries < 2) {
      try {
        await SupabaseService.client.auth.updateUser(
          UserAttributes(password: newPassword),
        ).timeout(const Duration(seconds: 15));

        _isPasswordRecoveryActive = false;
        await cryptoService.initialize();
        _state = AuthState.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        _errorMessage = _parseUserFriendlyError(e);
        break;
      } catch (e) {
        retries++;
        if (retries >= 2) {
          _errorMessage = _parseUserFriendlyError(e);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void cancelPasswordRecovery() {
    _isPasswordRecoveryActive = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    _state = AuthState.unauthenticated;
    _emailConfirmationPending = false;
    _pendingEmail = null;
    _isPasswordRecoveryActive = false;
    notifyListeners();
  }

  String _parseUserFriendlyError(dynamic e) {
    return ErrorUtils.toFriendlyMessage(e);
  }
}

