import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vault/screens/vault_screen.dart';
import 'features/settings/screens/settings_screen.dart';

class LockyApp extends StatelessWidget {
  const LockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Locky Bóveda',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: _buildHome(authProvider.state),
    );
  }

  Widget _buildHome(AuthState state) {
    switch (state) {
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.deviceLockRequired:
        return const LockScreen();
      case AuthState.authenticated:
        return const MainNavigationShell();
    }
  }
}

// Alias for backwards compatibility
typedef SureThingApp = LockyApp;

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Auto lock app immediately when user minimizes or switches apps
      Provider.of<AuthProvider>(context, listen: false).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.category_copy),
            selectedIcon: Icon(Iconsax.category),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.lock_1_copy),
            selectedIcon: Icon(Iconsax.lock_1),
            label: 'Bóveda',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.setting_2_copy),
            selectedIcon: Icon(Iconsax.setting_2),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
