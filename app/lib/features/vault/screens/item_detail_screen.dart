import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/vault_item_model.dart';
import '../providers/vault_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/glassmorphic_card.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../../../shared/utils/date_utils.dart';
import '../widgets/item_type_icon.dart';
import '../widgets/linked_items_list.dart';
import '../widgets/pattern_lock_widget.dart';
import 'item_form_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final VaultItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _showSecret = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vault = Provider.of<VaultProvider>(context);

    // Get latest version of item from provider if available
    final currentItem = vault.items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    final tagColorHex = currentItem.data['color_tag']?.toString();
    Color? tagColor;
    if (tagColorHex != null && tagColorHex.isNotEmpty) {
      try {
        final hex = tagColorHex.replaceAll('#', '');
        if (hex.length == 6) tagColor = Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: currentItem.title,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  ItemTypeIcon(itemType: currentItem.itemType, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    currentItem.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tagColor != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tagColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: tagColor),
                          const SizedBox(width: 6),
                          Text(
                            'Etiqueta',
                            style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Modificado: ${AppDateUtils.formatShort(currentItem.updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _confirmAndShare(context, currentItem),
                        icon: const Icon(Iconsax.share_copy, size: 18),
                        label: const Text('Compartir'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemFormScreen(itemToEdit: currentItem),
                            ),
                          );
                        },
                        icon: const Icon(Iconsax.edit_2_copy, size: 18),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        onPressed: () => _confirmDelete(context, vault, currentItem),
                        icon: const Icon(Iconsax.trash_copy, size: 18),
                        label: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (currentItem.itemType == 'pattern') ...[
              GlassmorphicCard(
                child: PatternLockWidget(
                  initialGridSize: int.tryParse(currentItem.data['pattern_grid_size']?.toString() ?? '3') ?? 3,
                  initialSequence: (currentItem.data['pattern_sequence'] as List?)
                          ?.map((e) => int.tryParse(e.toString()) ?? 0)
                          .toList() ??
                      [],
                  readOnly: true,
                ),
              ),
            ] else ...[
              GlassmorphicCard(
                child: Column(
                  children: currentItem.data.entries.where((e) => e.key != 'color_tag').map((entry) {
                    final key = entry.key;
                    final value = entry.value.toString();
                    final isSecret = key == 'password' || key == 'cvv' || key == 'api_secret' || key == 'pin';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (AppConstants.fieldLabels[key] ?? key).toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                                Text(
                                  isSecret && !_showSecret ? '••••••••••••' : value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSecret)
                                IconButton(
                                  icon: Icon(
                                    _showSecret ? Iconsax.eye_slash_copy : Iconsax.eye_copy,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showSecret = !_showSecret;
                                    });
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Iconsax.copy_copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: value));
                                  SnackbarUtils.showSuccess(context, 'Copiado al portapapeles');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 28),

            const SizedBox(height: 20),

            // Card de Auditoría e Historial
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.clock_copy, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Historial & Registro de Auditoría',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildAuditRow(context, 'Creado el', AppDateUtils.formatFull(currentItem.createdAt), Iconsax.calendar_add_copy),
                  const SizedBox(height: 8),
                  _buildAuditRow(context, 'Última Edición', AppDateUtils.formatFull(currentItem.updatedAt), Iconsax.edit_2_copy),
                  const SizedBox(height: 8),
                  _buildAuditRow(
                    context,
                    'Estado Respaldo',
                    currentItem.syncStatus == 'synced' ? 'Sincronizado en la nube' : 'Pendiente en este celular',
                    Iconsax.cloud_connection_copy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            LinkedItemsListWidget(
              currentItemId: currentItem.id,
              allItems: vault.items,
              links: vault.links,
              onAddLink: (targetId) {
                vault.linkItems(sourceItemId: currentItem.id, targetItemId: targetId);
                SnackbarUtils.showSuccess(context, 'Item enlazado con éxito');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VaultProvider vault, VaultItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar elemento?'),
        content: Text('¿Estás seguro de eliminar "${item.title}"? Podrás deshacerlo en los siguientes 5 segundos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pop(context); // Close ItemDetailScreen
      vault.deleteItemWithUndo(item, context);
    }
  }

  void _confirmAndShare(BuildContext context, VaultItemModel item) async {
    final String? shareText = await showDialog<String>(
      context: context,
      builder: (ctx) => ShareChecklistDialog(item: item),
    );

    if (shareText != null && shareText.isNotEmpty) {
      try {
        await Share.share(shareText, subject: 'Locky - ${item.title}');
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'Copiado al portapapeles en formato texto');
        }
      }
    }
  }
}

class ShareChecklistDialog extends StatefulWidget {
  final VaultItemModel item;

  const ShareChecklistDialog({super.key, required this.item});

  @override
  State<ShareChecklistDialog> createState() => _ShareChecklistDialogState();
}

class _ShareChecklistDialogState extends State<ShareChecklistDialog> {
  late Map<String, bool> _selectedFields;

  @override
  void initState() {
    super.initState();
    _selectedFields = {};
    widget.item.data.forEach((key, val) {
      if (val != null && val.toString().trim().isNotEmpty) {
        _selectedFields[key] = true;
      }
    });
  }

  String _getFieldLabel(String key) {
    if (AppConstants.fieldLabels.containsKey(key)) {
      return AppConstants.fieldLabels[key]!;
    }
    switch (key) {
      case 'username':
        return 'Usuario / Correo';
      case 'password':
        return 'Contraseña';
      case 'card_number':
        return 'Número de Tarjeta';
      case 'cardholder_name':
        return 'Nombre del Titular';
      case 'expiry_date':
        return 'Fecha de Vencimiento';
      case 'cvv':
        return 'Código CVV';
      case 'pin':
        return 'PIN de Cajero / Clave';
      case 'account_number':
        return 'Número de Cuenta';
      case 'url':
        return 'Sitio Web / URL';
      case 'content':
        return 'Contenido de la Nota';
      case 'pattern_grid_size':
        return 'Tamaño de Matriz';
      case 'pattern_sequence':
        return 'Secuencia de Patrón (Puntos)';
      case 'notes':
        return 'Notas Adicionales';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedFields.values.where((v) => v).length;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Iconsax.share_copy, color: Colors.amber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Seleccionar Datos a Compartir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marca únicamente los campos que deseas enviar por seguridad.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Elemento: ${widget.item.title}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Divider(),
            if (_selectedFields.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Este elemento no contiene datos legibles para compartir.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              )
            else
              ..._selectedFields.keys.map((key) {
                final label = _getFieldLabel(key);
                final val = widget.item.data[key].toString();
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    val.length > 25 ? '${val.substring(0, 25)}...' : val,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _selectedFields[key],
                  onChanged: (bool? checked) {
                    setState(() {
                      _selectedFields[key] = checked ?? false;
                    });
                  },
                );
              }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: selectedCount == 0
              ? null
              : () {
                  final buffer = StringBuffer();
                  buffer.writeln('📌 Credencial compartida desde Locky:');
                  buffer.writeln('• Elemento: ${widget.item.title}');
                  _selectedFields.forEach((k, isSelected) {
                    if (isSelected) {
                      final label = _getFieldLabel(k);
                      final val = widget.item.data[k].toString();
                      buffer.writeln('• $label: $val');
                    }
                  });

                  Navigator.pop(context, buffer.toString());
                },
          icon: const Icon(Iconsax.share_copy, size: 16),
          label: Text('Compartir ($selectedCount)'),
        ),
      ],
    );
  }
}
