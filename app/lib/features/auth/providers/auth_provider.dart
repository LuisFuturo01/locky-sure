import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/crypto/crypto_service.dart';

import '../../../shared/utils/error_utils.dart';

enum AuthState { unauthenticated, deviceLockRequired, authenticated }

class AuthProvider extends ChangeNotifier {
  final CryptoService cryptoService;
  final LocalAuthentication _localAuth = LocalAuthentication();

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

  AuthProvider({required this.cryptoService}) {
    checkCurrentSession();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        _emailConfirmationPending = false;
        if (_state == AuthState.unauthenticated) {
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
        await cryptoService.initialize();
        _state = AuthState.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _emailConfirmationPending = false;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://singular-melomakarona-bc5ce2.netlify.app',
      );

      if (response.user != null) {
        if (response.session == null) {
          // Email confirmation is required by Supabase Auth settings
          _emailConfirmationPending = true;
          _pendingEmail = email;
          _isLoading = false;
          notifyListeners();
          return false;
        } else {
          // Direct login (email confirmation disabled)
          await cryptoService.initialize();
          _state = AuthState.authenticated;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } on AuthException catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    } catch (e) {
      _errorMessage = _parseUserFriendlyError(e);
    }

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

  Future<bool> authenticateWithDeviceBiometrics() async {
    try {
      bool isSupported = await _localAuth.isDeviceSupported();
      bool canCheck = await _localAuth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        // Fallback for emulators without lock screen configured
        await cryptoService.initialize();
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
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
        redirectTo: 'https://magical-starship-e2f526.netlify.app',
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

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    _state = AuthState.unauthenticated;
    _emailConfirmationPending = false;
    _pendingEmail = null;
    notifyListeners();
  }

  String _parseUserFriendlyError(dynamic e) {
    return ErrorUtils.toFriendlyMessage(e);
  }
}
