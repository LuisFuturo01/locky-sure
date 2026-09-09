import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  AppThemeMode _currentTheme = AppThemeMode.emerald;

  AppThemeMode get currentThemeMode => _currentTheme;
  ThemeData get currentTheme => AppTheme.getTheme(_currentTheme);

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final saved = await _storage.read(key: AppConstants.themeKeyStorage);
    if (saved != null) {
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.emerald,
      );
      _currentTheme = mode;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _currentTheme = mode;
    notifyListeners();
    await _storage.write(
      key: AppConstants.themeKeyStorage,
      value: mode.name,
    );
  }
}
