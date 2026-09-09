import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ItemTypeIcon extends StatelessWidget {
  final String itemType;
  final double size;

  const ItemTypeIcon({
    super.key,
    required this.itemType,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (itemType) {
      case 'password':
        icon = Iconsax.lock_copy;
        color = const Color(0xFF10B981);
        break;
      case 'card':
        icon = Iconsax.card_copy;
        color = const Color(0xFFF472B6);
        break;
      case 'note':
        icon = Iconsax.note_copy;
        color = const Color(0xFF3B82F6);
        break;
      case 'identity':
        icon = Iconsax.user_copy;
        color = const Color(0xFFF59E0B);
        break;
      case 'api_key':
        icon = Iconsax.code_copy;
        color = const Color(0xFFA78BFA);
        break;
      default:
        icon = Iconsax.setting_copy;
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
