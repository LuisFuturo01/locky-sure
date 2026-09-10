import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../providers/auth_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.authenticateWithDeviceBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                          ),
                          child: Icon(
                            Iconsax.finger_scan_copy,
                            size: 46,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                Text(
                  'Locky Protegido',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Usa la huella, rostro, PIN o patrón de tu celular para ingresar',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                    ),
                    onPressed: _authenticate,
                    icon: const Icon(Iconsax.finger_cricle_copy),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Desbloquear con Credenciales del Celular',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Iconsax.logout_copy, size: 18),
                  label: const Text('Cerrar sesión de la cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
