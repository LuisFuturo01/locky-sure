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
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Iconsax.info_circle_copy, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de Uso de Locky',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Tu gestor seguro y personal',
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
                icon: Iconsax.key_copy,
                color: const Color(0xFF10B981),
                title: '¿Qué puedes almacenar?',
                content:
                    '• Contraseñas y Cuentas: Claves de correos, streaming o redes sociales.\n'
                    '• Tarjetas de Crédito/Débito: Números, fechas de vencimiento, CVV y PIN de cajero.\n'
                    '• Documentos e Identidad: Carnets (CI/DNI), matrículas o licencias sin exigir contraseña.\n'
                    '• Notas Confidenciales: PINs secretos, frases semilla o códigos de recuperación.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.task_square_copy,
                color: const Color(0xFF3B82F6),
                title: 'Acciones Rápida y Checklist',
                content:
                    '• Selección Múltiple: Mantén presionada cualquier tarjeta para seleccionar varios elementos y borrarlos a la vez.\n'
                    '• Creación de Carpetas: Agrupa tus registros y crea nuevas carpetas directamente desde el formulario.\n'
                    '• Compartir Carpetas: Envía resúmenes de credenciales mediante el botón Compartir con un práctico checklist.',
              ),
              const SizedBox(height: 20),

              _buildHelpSection(
                context,
                icon: Iconsax.cloud_change_copy,
                color: const Color(0xFF8B5CF6),
                title: 'Sincronización y Seguridad',
                content:
                    '• Cifrado en Celular: Tus datos se protegen directamente en tu teléfono antes de guardarse.\n'
                    '• Respaldo en la Nube: Si cuentas con conexión a internet, tus cambios se respaldan automáticamente.\n'
                    '• Modo Offline: Puedes usar la app sin internet; al reconectarte, todo se sincronizará.',
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
              const SizedBox(height: 16),
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
