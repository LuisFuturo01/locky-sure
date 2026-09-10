import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/vault_item_model.dart';
import '../models/folder_model.dart';
import '../providers/vault_provider.dart';
import '../providers/folder_provider.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/animated_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../widgets/vault_item_card.dart';
import '../widgets/folder_tree.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItemIds.clear();
      }
    });
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _selectAll(List<VaultItemModel> items) {
    setState(() {
      if (_selectedItemIds.length == items.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds.addAll(items.map((i) => i.id));
      }
    });
  }

  void _confirmBulkDelete(BuildContext context, VaultProvider vault, List<VaultItemModel> displayItems) {
    final selectedItems = displayItems.where((i) => _selectedItemIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar ${selectedItems.length} elementos?'),
        content: Text('¿Estás seguro de eliminar los ${selectedItems.length} elementos seleccionados de la bóveda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _toggleSelectionMode();
              vault.deleteMultipleItemsWithUndo(selectedItems, context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, FolderProvider folderProvider, FolderModel folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar carpeta "${folder.name}"?'),
        content: const Text('Los elementos guardados en esta carpeta no se borrarán, pero volverán a la carpeta raíz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await folderProvider.deleteFolder(folder.id);
              if (context.mounted) {
                SnackbarUtils.showSuccess(context, 'Carpeta "${folder.name}" eliminada');
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vault = Provider.of<VaultProvider>(context);
    final folder = Provider.of<FolderProvider>(context);

    final displayItems = folder.selectedFolderId == null
        ? vault.filteredItems
        : vault.filteredItems.where((i) => i.folderId == folder.selectedFolderId).toList();

    final allSelected = displayItems.isNotEmpty && _selectedItemIds.length == displayItems.length;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isSelectionMode ? '${_selectedItemIds.length} seleccionados' : 'Locky',
        actions: [
          IconButton(
            tooltip: _isSelectionMode ? 'Cancelar selección' : 'Borrado Masivo / Selección',
            icon: Icon(
              _isSelectionMode ? Icons.close_rounded : Iconsax.tick_square_copy,
              color: _isSelectionMode ? Colors.red : null,
            ),
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemFormScreen()),
                );
              },
              icon: const Icon(Iconsax.add_copy),
              label: const Text('Nuevo Item'),
            ),
      bottomNavigationBar: _isSelectionMode && displayItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () => _selectAll(displayItems),
                      icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all_rounded, size: 18),
                      label: Text(
                        allSelected ? 'Deseleccionar' : 'Todos',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () => _confirmBulkDelete(context, vault, displayItems),
                      icon: const Icon(Iconsax.trash_copy, color: Colors.white, size: 18),
                      label: Text(
                        'Eliminar (${_selectedItemIds.length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          final connectivity = Provider.of<ConnectivityService>(context, listen: false);
          final syncEngine = Provider.of<SyncEngine>(context, listen: false);
          if (!connectivity.isConnected) {
            if (context.mounted) {
              SnackbarUtils.showError(context, 'Sin conexión a Internet. Conéctate para sincronizar.');
            }
            return;
          }
          final success = await syncEngine.syncAll(onComplete: () async {
            await vault.loadItems();
            await folder.loadFolders();
          });
          if (context.mounted) {
            if (success) {
              SnackbarUtils.showSuccess(context, 'Sincronización completada');
            } else {
              final err = syncEngine.lastError ?? 'No se pudo sincronizar tus datos con tu cuenta. Revisa tu conexión a internet o intenta más tarde.';
              SnackbarUtils.showError(context, err);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              AnimatedSearchBar(
                onChanged: (val) => vault.setSearchQuery(val),
              ),
              const SizedBox(height: 16),

              FolderTreeWidget(
                folders: folder.folders,
                selectedFolderId: folder.selectedFolderId,
                onSelectFolder: (fId) => folder.selectFolder(fId),
                onCreateFolder: () => _showCreateFolderDialog(context),
                onDeleteFolder: (f) => _confirmDeleteFolder(context, folder, f),
                onShareFolder: (f) => _showShareFolderModal(context, vault, f),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: displayItems.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          EmptyStateWidget(
                            title: 'Bóveda vacía',
                            message: 'Añade tu primera contraseña o credencial privada.',
                            actionLabel: 'Crear Credencial',
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ItemFormScreen()),
                              );
                            },
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return VaultItemCard(
                            item: item,
                            isSelectionMode: _isSelectionMode,
                            isSelected: _selectedItemIds.contains(item.id),
                            onSelectChanged: (_) => _toggleSelectItem(item.id),
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedItemIds.add(item.id);
                                });
                              } else {
                                _toggleSelectItem(item.id);
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelectItem(item.id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItemDetailScreen(item: item),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Carpeta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre de carpeta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<FolderProvider>(context, listen: false)
                    .createFolder(name: nameController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showShareFolderModal(BuildContext context, VaultProvider vault, FolderModel folder) {
    final folderItems = vault.items.where((i) => i.folderId == folder.id).toList();

    if (folderItems.isEmpty) {
      SnackbarUtils.showError(context, 'La carpeta "${folder.name}" no tiene credenciales para compartir');
      return;
    }

    // Map: item.id -> Set of selected field keys
    final Map<String, Set<String>> selectedItemFields = {};
    for (final item in folderItems) {
      final available = _getAvailableFieldsForItem(item);
      selectedItemFields[item.id] = Set<String>.from(available.keys);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            int totalSelectedFields = 0;
            for (final fields in selectedItemFields.values) {
              totalSelectedFields += fields.length;
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.export_1_copy, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compartir Carpeta',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '📁 ${folder.name} (${folderItems.length} credenciales)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.select_all_rounded, size: 16),
                          label: const Text('Marcar Todo'),
                          onPressed: () {
                            setModalState(() {
                              for (final item in folderItems) {
                                final avail = _getAvailableFieldsForItem(item);
                                selectedItemFields[item.id] = Set<String>.from(avail.keys);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.security_rounded, size: 16),
                          label: const Text('Sin Contraseñas / PIN'),
                          onPressed: () {
                            setModalState(() {
                              for (final item in folderItems) {
                                final avail = _getAvailableFieldsForItem(item);
                                final keys = Set<String>.from(avail.keys);
                                keys.removeAll({'password', 'cvv', 'pin'});
                                selectedItemFields[item.id] = keys;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.deselect_rounded, size: 16),
                          label: const Text('Deseleccionar'),
                          onPressed: () {
                            setModalState(() {
                              for (final item in folderItems) {
                                selectedItemFields[item.id] = {};
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: folderItems.length,
                      itemBuilder: (context, idx) {
                        final item = folderItems[idx];
                        final available = _getAvailableFieldsForItem(item);
                        final currentSelected = selectedItemFields[item.id] ?? {};

                        IconData itemIcon;
                        switch (item.itemType) {
                          case 'card':
                            itemIcon = Iconsax.card_copy;
                            break;
                          case 'note':
                            itemIcon = Iconsax.note_copy;
                            break;
                          case 'identity':
                            itemIcon = Iconsax.user_copy;
                            break;
                          default:
                            itemIcon = Iconsax.lock_copy;
                        }

                        final allItemFieldsChecked = available.isNotEmpty && currentSelected.length == available.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: currentSelected.isNotEmpty
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : theme.colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: Checkbox(
                                value: allItemFieldsChecked ? true : (currentSelected.isEmpty ? false : null),
                                tristate: true,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedItemFields[item.id] = Set<String>.from(available.keys);
                                    } else {
                                      selectedItemFields[item.id] = {};
                                    }
                                  });
                                },
                              ),
                              title: Row(
                                children: [
                                  Icon(itemIcon, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${currentSelected.length} de ${available.length} datos seleccionados',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: currentSelected.isNotEmpty
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                  child: Column(
                                    children: available.entries.map((entry) {
                                      final fieldKey = entry.key;
                                      final fieldText = entry.value;
                                      final isFieldChecked = currentSelected.contains(fieldKey);

                                      return CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        value: isFieldChecked,
                                        title: Text(
                                          fieldText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isFieldChecked ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setModalState(() {
                                            if (val == true) {
                                              selectedItemFields[item.id]?.add(fieldKey);
                                            } else {
                                              selectedItemFields[item.id]?.remove(fieldKey);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: totalSelectedFields == 0
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final buffer = StringBuffer();
                              buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                              buffer.writeln('REPORTE DE CREDENCIALES SELECCIONADAS');
                              buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

                              int sharedCount = 0;
                              for (final item in folderItems) {
                                final activeFields = selectedItemFields[item.id] ?? {};
                                if (activeFields.isEmpty) continue;

                                sharedCount++;
                                final available = _getAvailableFieldsForItem(item);
                                buffer.writeln('$sharedCount. ${item.title}');

                                for (final entry in available.entries) {
                                  if (activeFields.contains(entry.key)) {
                                    buffer.writeln('   • ${entry.value}');
                                  }
                                }
                                buffer.writeln();
                              }

                              buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                              buffer.writeln('Información emitida desde la aplicación Locky.');

                              await Share.share(buffer.toString(), subject: 'Locky - Credenciales');
                            },
                      icon: const Icon(Iconsax.export_1_copy),
                      label: Text('Compartir ($totalSelectedFields) Datos Seleccionados'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, String> _getAvailableFieldsForItem(VaultItemModel item) {
    final result = <String, String>{};
    final data = item.data;

    if (item.itemType == 'card') {
      if (data.containsKey('cardholder_name') && data['cardholder_name'].toString().trim().isNotEmpty) {
        result['cardholder_name'] = 'Titular: ${data['cardholder_name']}';
      }
      if (data.containsKey('card_number') && data['card_number'].toString().trim().isNotEmpty) {
        result['card_number'] = 'N° Tarjeta: ${data['card_number']}';
      }
      if (data.containsKey('expiry_date') && data['expiry_date'].toString().trim().isNotEmpty) {
        result['expiry_date'] = 'Vencimiento: ${data['expiry_date']}';
      }
      if (data.containsKey('cvv') && data['cvv'].toString().trim().isNotEmpty) {
        result['cvv'] = 'CVV: ${data['cvv']}';
      }
      if (data.containsKey('account_number') && data['account_number'].toString().trim().isNotEmpty) {
        result['account_number'] = 'N° de Cuenta: ${data['account_number']}';
      }
      if (data.containsKey('pin') && data['pin'].toString().trim().isNotEmpty) {
        result['pin'] = 'PIN: ${data['pin']}';
      }
    } else if (item.itemType == 'identity') {
      if (data.containsKey('username') && data['username'].toString().trim().isNotEmpty) {
        result['username'] = 'Titular: ${data['username']}';
      }
      if (data.containsKey('document_number') && data['document_number'].toString().trim().isNotEmpty) {
        result['document_number'] = 'N° Documento / CI: ${data['document_number']}';
      } else if (data.containsKey('card_number') && data['card_number'].toString().trim().isNotEmpty) {
        result['document_number'] = 'N° Documento / CI: ${data['card_number']}';
      }
    } else if (item.itemType == 'note') {
      if (data.containsKey('content') && data['content'].toString().trim().isNotEmpty) {
        result['content'] = 'Contenido Nota: ${data['content']}';
      }
    } else {
      if (data.containsKey('username') && data['username'].toString().trim().isNotEmpty) {
        result['username'] = 'Usuario / Correo: ${data['username']}';
      }
      if (data.containsKey('password') && data['password'].toString().trim().isNotEmpty) {
        result['password'] = 'Contraseña: ${data['password']}';
      }
      if (data.containsKey('url') && data['url'].toString().trim().isNotEmpty) {
        result['url'] = 'Sitio Web: ${data['url']}';
      }
    }

    if (data.containsKey('notes') && data['notes'].toString().trim().isNotEmpty) {
      result['notes'] = 'Notas: ${data['notes']}';
    }

    // Dynamic scan for any extra non-empty custom key in data
    data.forEach((key, value) {
      if (key == 'color_tag' || key == 'sync_status' || result.containsKey(key)) return;
      final valStr = value?.toString().trim() ?? '';
      if (valStr.isNotEmpty) {
        result[key] = '$key: $valStr';
      }
    });

    return result;
  }
}
