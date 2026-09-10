import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../shared/utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (authProvider.isPasswordRecoveryActive) {
      return _buildPasswordResetView(context, authProvider);
    }

    if (authProvider.emailConfirmationPending) {
      return _buildEmailVerificationView(context, authProvider);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Icon(
                          Iconsax.security_safe_copy,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Locky',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bóveda Privada de Credenciales',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Tab Switcher
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isSignUp ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isSignUp ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isSignUp ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Iconsax.sms_copy),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Iconsax.key_copy),
                  ),
                ),
                
                if (!_isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context, authProvider),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ] else const SizedBox(height: 24),

                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final pass = _passwordController.text.trim();
                            if (email.isEmpty || pass.isEmpty) {
                              SnackbarUtils.showError(context, 'Ingresa correo y contraseña');
                              return;
                            }

                            if (_isSignUp) {
                              await authProvider.signUpWithEmail(email, pass);
                            } else {
                              await authProvider.signInWithEmail(email, pass);
                            }
                          },
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'Registrarse en Locky' : 'Ingresar a la Bóveda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationView(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.sms_tracking_copy,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Verifica tu Correo!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Enviamos un enlace de confirmación a:\n${authProvider.pendingEmail ?? ""}\n\nAbre tu correo electrónico y haz clic en el enlace para activar tu cuenta e ingresar automáticamente a la Bóveda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                if (authProvider.errorMessage != null) ...[
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            await authProvider.resendVerificationEmail();
                            if (context.mounted) {
                              SnackbarUtils.showSuccess(context, 'Enlace de confirmación reenviado a tu correo');
                            }
                          },
                    icon: authProvider.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Iconsax.refresh_copy, size: 18),
                    label: const Text('Reenviar Enlace al Correo'),
                  ),
                ),
                const SizedBox(height: 14),

                TextButton(
                  onPressed: () {
                    authProvider.cancelEmailConfirmation();
                  },
                  child: const Text('Volver al Inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetView(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.key_copy,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nueva Contraseña',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Has verificado tu identidad mediante el enlace de correo. Ingresa tu nueva contraseña para ingresar a Locky:',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: Icon(Iconsax.key_copy),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: Icon(Iconsax.key_copy),
                  ),
                ),
                const SizedBox(height: 20),

                if (authProvider.errorMessage != null) ...[
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            final newPass = _newPasswordController.text.trim();
                            final confirmPass = _confirmPasswordController.text.trim();

                            if (newPass.isEmpty || newPass.length < 6) {
                              SnackbarUtils.showError(context, 'La contraseña debe tener al menos 6 caracteres');
                              return;
                            }
                            if (newPass != confirmPass) {
                              SnackbarUtils.showError(context, 'Las contraseñas no coinciden');
                              return;
                            }

                            final success = await authProvider.updatePassword(newPass);
                            if (context.mounted && success) {
                              SnackbarUtils.showSuccess(context, '¡Contraseña actualizada exitosamente!');
                            }
                          },
                    icon: authProvider.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Iconsax.security_user_copy, size: 18),
                    label: const Text('Actualizar e Ingresar'),
                  ),
                ),
                const SizedBox(height: 14),

                TextButton(
                  onPressed: () {
                    authProvider.cancelPasswordRecovery();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, AuthProvider authProvider) {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.key_copy, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Recuperar Contraseña',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa tu correo registrado. Te enviaremos un enlace seguro para restablecer tu contraseña:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Iconsax.sms_copy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () async {
                    final email = resetEmailController.text.trim();
                    if (email.isEmpty) {
                      SnackbarUtils.showError(context, 'Ingresa tu correo electrónico');
                      return;
                    }

                    final success = await authProvider.resetPassword(email);
                    if (context.mounted) {
                      if (success) {
                        Navigator.pop(ctx);
                        SnackbarUtils.showSuccess(
                          context,
                          'Enlace enviado a $email. Revisa tu correo.',
                        );
                      } else if (authProvider.errorMessage != null) {
                        SnackbarUtils.showError(context, authProvider.errorMessage!);
                      }
                    }
                  },
            child: authProvider.isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar Enlace'),
          ),
        ],
      ),
    );
  }
}
