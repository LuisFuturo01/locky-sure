import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/folder_model.dart';

class FolderTreeWidget extends StatelessWidget {
  final List<FolderModel> folders;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelectFolder;
  final VoidCallback onCreateFolder;
  final ValueChanged<FolderModel>? onDeleteFolder;
  final ValueChanged<FolderModel>? onShareFolder;

  const FolderTreeWidget({
    super.key,
    required this.folders,
    required this.selectedFolderId,
    required this.onSelectFolder,
    required this.onCreateFolder,
    this.onDeleteFolder,
    this.onShareFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFolder = folders.cast<FolderModel?>().firstWhere(
          (f) => f?.id == selectedFolderId,
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Carpetas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (selectedFolder != null && onShareFolder != null) ...[
                  IconButton(
                    tooltip: 'Compartir carpeta "${selectedFolder.name}"',
                    icon: const Icon(Iconsax.export_1_copy, size: 20, color: Color(0xFF6366F1)),
                    onPressed: () => onShareFolder!(selectedFolder),
                  ),
                ],
                IconButton(
                  tooltip: 'Nueva carpeta',
                  icon: const Icon(Iconsax.folder_add_copy, size: 20),
                  onPressed: onCreateFolder,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Todas'),
                  selected: selectedFolderId == null,
                  onSelected: (_) => onSelectFolder(null),
                ),
              ),
              ...folders.map((folder) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      avatar: const Icon(Iconsax.folder_copy, size: 16),
                      label: Text(folder.name),
                      selected: selectedFolderId == folder.id,
                      onPressed: () => onSelectFolder(folder.id),
                      onDeleted: onDeleteFolder != null ? () => onDeleteFolder!(folder) : null,
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
