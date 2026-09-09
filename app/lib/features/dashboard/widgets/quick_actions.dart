import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onAddPassword;
  final VoidCallback onAddNote;
  final VoidCallback onAddCard;

  const QuickActionsWidget({
    super.key,
    required this.onAddPassword,
    required this.onAddNote,
    required this.onAddCard,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            context,
            label: 'Contraseña',
            icon: Iconsax.lock_copy,
            color: const Color(0xFF10B981),
            onTap: onAddPassword,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            context,
            label: 'Nota',
            icon: Iconsax.note_copy,
            color: const Color(0xFF3B82F6),
            onTap: onAddNote,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            context,
            label: 'Tarjeta',
            icon: Iconsax.card_copy,
            color: const Color(0xFFF472B6),
            onTap: onAddCard,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
