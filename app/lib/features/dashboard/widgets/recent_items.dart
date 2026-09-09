import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../vault/models/vault_item_model.dart';
import '../../../shared/widgets/glassmorphic_card.dart';

class RecentItemsWidget extends StatelessWidget {
  final List<VaultItemModel> items;
  final ValueChanged<VaultItemModel> onItemTap;

  const RecentItemsWidget({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agregados Recientemente',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassmorphicCard(
                onTap: () => onItemTap(item),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForType(item.itemType),
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.itemType.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
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
          },
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'password':
        return Iconsax.lock_copy;
      case 'card':
        return Iconsax.card_copy;
      case 'note':
        return Iconsax.note_copy;
      case 'identity':
        return Iconsax.user_copy;
      case 'api_key':
        return Iconsax.code_copy;
      default:
        return Iconsax.setting_copy;
    }
  }
}
