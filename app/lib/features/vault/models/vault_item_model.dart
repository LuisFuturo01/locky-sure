class VaultItemModel {
  final String id;
  final String userId;
  final String? folderId;
  final String itemType;
  final String title; // Decrypted title
  final Map<String, dynamic> data; // Decrypted payload fields (url, password, username, etc.)
  final bool isFavorite;
  final int sortOrder;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultItemModel({
    required this.id,
    required this.userId,
    this.folderId,
    required this.itemType,
    required this.title,
    required this.data,
    this.isFavorite = false,
    this.sortOrder = 0,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });

  VaultItemModel copyWith({
    String? id,
    String? userId,
    String? folderId,
    String? itemType,
    String? title,
    Map<String, dynamic>? data,
    bool? isFavorite,
    int? sortOrder,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      folderId: folderId ?? this.folderId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      data: data ?? this.data,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
