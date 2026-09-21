import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../shared/utils/snackbar_utils.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  bool _hasLocalPin = false;
  bool _hasSystemLock = true;
  bool _obscurePin = true;
  bool _isVerifyingPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLockState();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initLockState() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasPin = await auth.isLocalPinSet();
    final hasSys = await auth.hasSystemLockScreen();

    if (mounted) {
      setState(() {
        _hasLocalPin = hasPin;
        _hasSystemLock = hasSys;
      });
    }

    if (hasSys) {
      await _authenticateBiometrics();
    }
  }

  Future<void> _authenticateBiometrics() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.authenticateWithDeviceBiometrics();
    if (!success && mounted) {
      final hasSys = await auth.hasSystemLockScreen();
      setState(() {
        _hasSystemLock = hasSys;
      });
      if (!hasSys && auth.errorMessage != null) {
        SnackbarUtils.showError(context, auth.errorMessage!);
      }
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      SnackbarUtils.showError(context, 'Por favor ingresa tu PIN local');
      return;
    }

    setState(() => _isVerifyingPin = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.authenticateWithLocalPin(pin);
    setState(() => _isVerifyingPin = false);

    if (!success && mounted) {
      SnackbarUtils.showError(context, auth.errorMessage ?? 'PIN incorrecto');
    }
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
                  'Crear PIN Local',
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
                  'Crea una clave numérica (4 a 6 dígitos) para desbloquear Locky en este celular.',
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
                  SnackbarUtils.showError(context, 'El PIN debe tener al menos 4 dígitos');
                  return;
                }

                if (pin != confirm) {
                  SnackbarUtils.showError(context, 'Los PINs no coinciden');
                  return;
                }

                await auth.setLocalAppPin(pin);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  setState(() {
                    _hasLocalPin = true;
                  });
                  SnackbarUtils.showSuccess(
                    context,
                    '¡PIN de acceso local creado! Ingresa tu PIN para desbloquear.',
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
                    _hasLocalPin
                        ? 'Ingresa tu PIN local para desbloquear'
                        : (_hasSystemLock
                            ? 'Usa la huella, rostro, PIN o patrón de tu celular para ingresar'
                            : 'Tu celular no cuenta con seguridad de pantalla'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_hasSystemLock && !_hasLocalPin) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Iconsax.security_safe_copy, color: Colors.orange, size: 36),
                          const SizedBox(height: 10),
                          const Text(
                            'Sin seguridad en el celular',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tu celular no tiene PIN, patrón ni huella configurada. Crea un PIN de acceso local para desbloquear la app sin subir datos a la nube.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showCreatePinModal(context, auth),
                              icon: const Icon(Iconsax.key_copy, size: 18),
                              label: const Text('Crear PIN de Acceso Local'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_hasLocalPin) ...[
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: _obscurePin,
                      maxLength: 6,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'PIN de Acceso Local',
                        hintText: 'Ingresa tu PIN',
                        prefixIcon: const Icon(Iconsax.key_copy),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Iconsax.eye_copy : Iconsax.eye_slash_copy, size: 20),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      onSubmitted: (_) => _unlockWithPin(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: _isVerifyingPin ? null : _unlockWithPin,
                        icon: _isVerifyingPin
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Iconsax.security_safe_copy),
                        label: const Text('Desbloquear con PIN'),
                      ),
                    ),
                    if (_hasSystemLock) const SizedBox(height: 16),
                  ],

                  if (_hasSystemLock) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: _authenticateBiometrics,
                        icon: const Icon(Iconsax.finger_cricle_copy),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Desbloquear con Huella / Celular',
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
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

