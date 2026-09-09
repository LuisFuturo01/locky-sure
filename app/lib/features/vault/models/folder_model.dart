class FolderModel {
  final String id;
  final String userId;
  final String? parentId;
  final String name; // Decrypted name for UI use
  final String icon;
  final String color;
  final int sortOrder;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    this.icon = 'folder',
    this.color = '#6366F1',
    this.sortOrder = 0,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'parent_id': parentId,
        'name': name,
        'icon': icon,
        'color': color,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
