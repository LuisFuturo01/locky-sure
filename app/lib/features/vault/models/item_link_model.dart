class ItemLinkModel {
  final String id;
  final String sourceItemId;
  final String targetItemId;
  final String linkType; // 'related', 'derived', 'parent'
  final DateTime createdAt;

  ItemLinkModel({
    required this.id,
    required this.sourceItemId,
    required this.targetItemId,
    this.linkType = 'related',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_item_id': sourceItemId,
        'target_item_id': targetItemId,
        'link_type': linkType,
        'created_at': createdAt.toIso8601String(),
      };
}
