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
                  TextButton.icon(
                    onPressed: () => _selectAll(displayItems),
                    icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all_rounded),
                    label: Text(allSelected ? 'Deseleccionar' : 'Todos'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _selectedItemIds.isEmpty
                        ? null
                        : () => _confirmBulkDelete(context, vault, displayItems),
                    icon: const Icon(Iconsax.trash_copy, color: Colors.white, size: 18),
                    label: Text(
                      'Eliminar (${_selectedItemIds.length})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    final selectedIds = Set<String>.from(folderItems.map((i) => i.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final allChecked = selectedIds.length == folderItems.length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
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
                              folder.name,
                              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Credenciales a incluir:',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            if (allChecked) {
                              selectedIds.clear();
                            } else {
                              selectedIds.addAll(folderItems.map((i) => i.id));
                            }
                          });
                        },
                        icon: Icon(allChecked ? Icons.deselect_rounded : Icons.select_all_rounded, size: 16),
                        label: Text(allChecked ? 'Deseleccionar' : 'Todos'),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: folderItems.length,
                      itemBuilder: (context, idx) {
                        final item = folderItems[idx];
                        final isChecked = selectedIds.contains(item.id);

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

                        final subtitle = item.data['username']?.toString() ??
                            item.data['document_number']?.toString() ??
                            item.data['card_number']?.toString() ??
                            item.itemType;

                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          secondary: Icon(itemIcon, color: theme.colorScheme.primary),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIds.add(item.id);
                              } else {
                                selectedIds.remove(item.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final selectedItems = folderItems.where((i) => selectedIds.contains(i.id)).toList();
                              final buffer = StringBuffer();
                              buffer.writeln('🔒 Locky - Credenciales Compartidas');
                              buffer.writeln('📁 Carpeta: ${folder.name}');
                              buffer.writeln('----------------------------------------\n');

                              for (int i = 0; i < selectedItems.length; i++) {
                                final item = selectedItems[i];
                                buffer.writeln('${i + 1}. 📌 ${item.title}');
                                if (item.itemType == 'card') {
                                  if (item.data.containsKey('card_number')) buffer.writeln('   • N° Tarjeta: ${item.data['card_number']}');
                                  if (item.data.containsKey('cardholder_name')) buffer.writeln('   • Titular: ${item.data['cardholder_name']}');
                                  if (item.data.containsKey('expiry_date')) buffer.writeln('   • Vencimiento: ${item.data['expiry_date']}');
                                  if (item.data.containsKey('cvv')) buffer.writeln('   • CVV: ${item.data['cvv']}');
                                } else if (item.itemType == 'note') {
                                  if (item.data.containsKey('content')) buffer.writeln('   • Nota: ${item.data['content']}');
                                } else if (item.itemType == 'identity') {
                                  if (item.data.containsKey('username')) buffer.writeln('   • Titular: ${item.data['username']}');
                                  if (item.data.containsKey('document_number')) buffer.writeln('   • Doc / CI: ${item.data['document_number']}');
                                } else {
                                  if (item.data.containsKey('username')) buffer.writeln('   • Usuario: ${item.data['username']}');
                                  if (item.data.containsKey('password')) buffer.writeln('   • Contraseña: ${item.data['password']}');
                                  if (item.data.containsKey('url')) buffer.writeln('   • URL: ${item.data['url']}');
                                }
                                if (item.data.containsKey('notes') && item.data['notes'].toString().isNotEmpty) {
                                  buffer.writeln('   • Notas: ${item.data['notes']}');
                                }
                                buffer.writeln();
                              }

                              buffer.writeln('----------------------------------------');
                              buffer.writeln('Enviado desde Locky.');

                              await Share.share(buffer.toString(), subject: 'Locky - Carpeta ${folder.name}');
                            },
                      icon: const Icon(Iconsax.export_1_copy),
                      label: Text('Compartir (${selectedIds.length}) Seleccionados'),
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
}
