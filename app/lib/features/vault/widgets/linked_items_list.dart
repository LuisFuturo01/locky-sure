import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/vault_item_model.dart';
import '../models/item_link_model.dart';

class LinkedItemsListWidget extends StatelessWidget {
  final String currentItemId;
  final List<VaultItemModel> allItems;
  final List<ItemLinkModel> links;
  final Function(String targetId) onAddLink;

  const LinkedItemsListWidget({
    super.key,
    required this.currentItemId,
    required this.allItems,
    required this.links,
    required this.onAddLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemLinks = links
        .where((l) => l.sourceItemId == currentItemId || l.targetItemId == currentItemId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items Enlazados / Derivados',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.link_copy, size: 20),
              onPressed: () => _showLinkDialog(context),
            ),
          ],
        ),
        if (itemLinks.isEmpty)
          Text(
            'Sin enlaces. Puedes vincular esta cuenta con otras credenciales.',
            style: theme.textTheme.bodySmall,
          )
        else
          ...itemLinks.map((link) {
            final targetId = link.sourceItemId == currentItemId
                ? link.targetItemId
                : link.sourceItemId;
            final targetItem = allItems.firstWhere(
              (i) => i.id == targetId,
              orElse: () => VaultItemModel(
                id: '',
                userId: '',
                itemType: 'password',
                title: 'Item no encontrado',
                data: {},
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.link_2_copy),
              title: Text(targetItem.title),
              subtitle: Text('Relación: ${link.linkType}'),
            );
          }),
      ],
    );
  }

  void _showLinkDialog(BuildContext context) {
    final availableItems = allItems.where((i) => i.id != currentItemId).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enlazar con otro item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableItems.length,
            itemBuilder: (context, index) {
              final item = availableItems[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.itemType),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddLink(item.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
