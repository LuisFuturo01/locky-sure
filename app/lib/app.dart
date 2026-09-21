import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'core/theme/theme_provider.dart';
import 'core/sync/sync_engine.dart';
import 'core/network/connectivity_service.dart';
import 'core/supabase/supabase_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vault/screens/vault_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class LockyApp extends StatefulWidget {
  const LockyApp({super.key});

  @override
  State<LockyApp> createState() => _LockyAppState();
}

class _LockyAppState extends State<LockyApp> {
  AuthState? _previousAuthState;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // If app becomes locked or unauthenticated, clear any pushed routes or dialogs immediately
    if (_previousAuthState != null &&
        _previousAuthState != authProvider.state &&
        authProvider.state != AuthState.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      });
    }
    _previousAuthState = authProvider.state;

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Locky',
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
  late final PageController _pageController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncEngine = Provider.of<SyncEngine>(context, listen: false);
      final connectivity = Provider.of<ConnectivityService>(context, listen: false);
      if (connectivity.isConnected && SupabaseService.isAuthenticated) {
        syncEngine.syncAll();
      }
      _checkInsecureDevicePrompt();
    });
  }

  Future<void> _checkInsecureDevicePrompt() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasSystemLock = await auth.hasSystemLockScreen();
    final hasLocalPin = await auth.isLocalPinSet();

    if (!hasSystemLock && !hasLocalPin && mounted) {
      _showInsecureDeviceDialog(context, auth);
    }
  }

  void _showInsecureDeviceDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.security_safe_copy, color: Colors.orange.shade700, size: 26),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tu celular no es seguro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Detectamos que tu dispositivo no cuenta con un bloqueo de pantalla (PIN, patrón, huella o contraseña).\n\n'
          '¿Deseas proteger tu app Locky creando un PIN de acceso local?\n\n'
          '• Esta clave se guardará únicamente en la memoria segura de tu celular.\n'
          '• Nunca se enviará a la nube.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ahora no'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showCreatePinModal(context, auth);
            },
            icon: const Icon(Iconsax.key_copy, size: 18),
            label: const Text('Crear PIN Local'),
          ),
        ],
      ),
    );
  }

  void _showCreatePinModal(BuildContext context, AuthProvider auth) {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    bool obscurePin = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Iconsax.security_safe_copy, color: Colors.blueAccent, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Crear PIN de Acceso',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa una clave numérica (4 a 6 dígitos) para proteger el acceso local a Locky.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: obscurePin,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Nuevo PIN Local',
                    hintText: 'Ej: 1234',
                    prefixIcon: const Icon(Iconsax.key_copy),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePin ? Iconsax.eye_copy : Iconsax.eye_slash_copy, size: 20),
                      onPressed: () => setModalState(() => obscurePin = !obscurePin),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: obscurePin,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Confirmar PIN',
                    hintText: 'Repite tu PIN',
                    prefixIcon: Icon(Iconsax.key_copy),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmPinController.text.trim();

                if (pin.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El PIN debe tener al menos 4 dígitos')),
                  );
                  return;
                }

                if (pin != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Los PINs no coinciden')),
                  );
                  return;
                }

                await auth.setLocalAppPin(pin);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡PIN de acceso local configurado exitosamente!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Guardar PIN'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock app ONLY when minimized or moved to background (paused), NOT when pulling status/notification bar (inactive)
    if (state == AppLifecycleState.paused) {
      Provider.of<AuthProvider>(context, listen: false).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Salir de Locky?'),
            content: const Text('¿Estás seguro de que deseas salir de la aplicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Salir', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
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
      ),
    );
  }
}
