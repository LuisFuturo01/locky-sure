import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final bool showHelp;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.showHelp = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _showHelpModal(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Iconsax.info_circle_copy, color: theme.colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía Completa de Locky',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Text(
                          'Todo lo que necesitas saber para usar tu app',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              _buildHelpSection(
                context,
                icon: Iconsax.shield_tick_copy,
                color: const Color(0xFF6366F1),
                title: '1. ¿Qué es Locky y cuál es su objetivo?',
                content:
                    'Locky es tu bóveda personal de alta seguridad. Cifra y almacena tus contraseñas, documentos de identidad, tarjetas de crédito/débito y notas secretas directamente en tu teléfono con encriptación AES-256.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.category_copy,
                color: const Color(0xFF10B981),
                title: '2. Categorías de Información (¿Qué guardar?)',
                content:
                    '• 🔑 Cuentas / Login: Registra correo, usuario, contraseña y enlace web (ej. Netflix, Gmail, Banco).\n'
                    '• 💳 Tarjetas Bancarias: Guarda el titular, número de tarjeta, vencimiento, CVV, PIN de cajero y N° de cuenta asociada.\n'
                    '• 🪪 Identidad y Documentos: Almacena Carnets (CI/DNI), Licencias de Conducir o Matrículas universitarias con Nombre y Número de Documento (sin exigir contraseña).\n'
                    '• 📝 Notas Seguras: Almacena frases de recuperación, PINs secretos o información confidencial.\n'
                    '• 💻 API Keys: Guarda claves y tokens de desarrollador.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.element_4_copy,
                color: const Color(0xFFEC4899),
                title: '3. Guía Detallada de Botones e Iconos',
                content:
                    '• 🔍 Buscador: Filtra tus registros en tiempo real por nombre o correo.\n'
                    '• 📋 Checklist / Selección Masiva (Icono arriba derecha): Activa el modo selección. También puedes mantener presionada cualquier tarjeta para marcar varios elementos y borrarlos a la vez.\n'
                    '• ℹ️ Asistencia (Icono ayuda): Abre este manual explicativo.\n'
                    '• ➕ Nuevo Item (Botón flotante inferior): Abre el formulario para guardar cualquier clave.\n'
                    '• 📁 Botón "+" de Carpetas: Crea nuevas carpetas directamente desde la bóveda o en el propio formulario al registrar un elemento.\n'
                    '• 📤 Compartir Carpeta (Icono al lado de carpetas): Abre el panel para elegir exactamente qué credenciales y qué campos específicos enviar.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.setting_2_copy,
                color: const Color(0xFFF59E0B),
                title: '4. ¿Qué hay en la Pantalla de Ajustes?',
                content:
                    '• 🎨 Selector de Temas Visuales: Elige entre varios colores de interfaz (Índigo, Rojo Red, Oscuro, Claro).\n'
                    '• 📶 Estado de Red: Te muestra si estás conectado a internet o guardando localmente en el celular.\n'
                    '• 🔄 Sincronizar Ahora: Botón para forzar el respaldo inmediato de tus datos pendientes con tu cuenta.\n'
                    '• 🚪 Cerrar Sesión: Sale de tu cuenta Locky de forma segura.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.wifi_square_copy,
                color: const Color(0xFF06B6D4),
                title: '5. ¿Qué pasa con Internet y la Sincronización?',
                content:
                    '• Funcionamiento 100% Offline: Locky funciona perfectamente en modo avión o sin red. Todo se guarda cifrado en tu teléfono.\n'
                    '• Auto-Sincronización: Al volver a tener señal de internet, Locky respalda automáticamente tus cambios en segundo plano.\n'
                    '• Carga Inteligente: El sistema cuenta con control de errores y tiempos límite para evitar que el indicador de sincronización se quede colgado.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.finger_scan_copy,
                color: const Color(0xFFEF4444),
                title: '6. Bloqueo de Seguridad Celular',
                content:
                    '• Al salir, pausar o minimizar la aplicación, Locky se bloquea automáticamente al instante.\n'
                    '• Para volver a ingresar, te solicitará la huella digital, rostro o el PIN de tu teléfono.\n'
                    '• El bloqueo es infranqueable: ningun gesto o botón Atrás permite saltarse la pantalla de autenticación.',
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Iconsax.tick_circle_copy),
                  label: const Text('Entendido, Volver a la App'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedActions = <Widget>[];
    if (actions != null) {
      combinedActions.addAll(actions!);
    }

    if (showHelp) {
      combinedActions.add(
        IconButton(
          tooltip: 'Ayuda y Guía de Uso',
          icon: const Icon(Iconsax.info_circle_copy),
          onPressed: () => _showHelpModal(context),
        ),
      );
    }

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ],
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: showBack,
      actions: combinedActions,
    );
  }
}
