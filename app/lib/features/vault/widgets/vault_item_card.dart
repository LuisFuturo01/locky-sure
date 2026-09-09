import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/vault_item_model.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/utils/snackbar_utils.dart';
import 'item_type_icon.dart';

class VaultItemCard extends StatelessWidget {
  final VaultItemModel item;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const VaultItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passwordVal = item.data['password']?.toString() ?? '';
    final tagColorHex = item.data['color_tag']?.toString();
    Color? tagColor;
    if (tagColorHex != null && tagColorHex.isNotEmpty) {
      try {
        final hex = tagColorHex.replaceAll('#', '');
        if (hex.length == 6) tagColor = Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassmorphicCard(
        onTap: isSelectionMode
            ? () => onSelectChanged?.call(!isSelected)
            : onTap,
        child: Row(
          children: [
            if (tagColor != null && !isSelectionMode) ...[
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: tagColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            ItemTypeIcon(itemType: item.itemType),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tagColor != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.data['username'] != null && item.data['username'].toString().isNotEmpty)
                    Text(
                      item.data['username'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),

            if (passwordVal.isNotEmpty)
              IconButton(
                tooltip: 'Copiar Clave',
                icon: const Icon(Iconsax.copy_copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: passwordVal));
                  SnackbarUtils.showSuccess(context, 'Contraseña copiada 📋');
                },
              ),

            const SizedBox(width: 4),
            Icon(
              item.syncStatus == 'synced'
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_upload_outlined,
              size: 18,
              color: item.syncStatus == 'synced' ? Colors.green : Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
