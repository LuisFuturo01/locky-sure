import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../providers/vault_provider.dart';
import '../providers/folder_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/animated_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/vault_item_card.dart';
import '../widgets/folder_tree.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/vault_item_model.dart';
import '../models/folder_model.dart';
import '../providers/vault_provider.dart';
import '../providers/folder_provider.dart';
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
        title: _isSelectionMode ? '${_selectedItemIds.length} seleccionados' : 'Bóveda de Credenciales',
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
      body: Padding(
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
            ),
            const SizedBox(height: 16),

            Expanded(
              child: displayItems.isEmpty
                  ? EmptyStateWidget(
                      title: 'Bóveda vacía',
                      message: 'Añade tu primera contraseña o credencial privada.',
                      actionLabel: 'Crear Credencial',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ItemFormScreen()),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        return VaultItemCard(
                          item: item,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedItemIds.contains(item.id),
                          onSelectChanged: (_) => _toggleSelectItem(item.id),
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
}
