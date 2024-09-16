class Location {
  int? id;
  String? emoji;
  String name;
  ElementType? elementType;
  bool enabled;
  OnClickAction? onClickAction;
  int? columnIndex;
  int? rowIndex;
  String? dialogName;
  int? imageId;
  bool? isCapacitySelectable;
  bool isCloseable;
  int? parentId;
  int? rootLocationId;
  final DateTime? closedAt;
  final DateTime? deletedAt;
  final bool isOfficial;
  final String? createdBy;
  int? dialogId;
  @Deprecated("Should be obtained via API")
  List<Location> children;

  Location({
    this.id,
    required this.name,
    this.emoji,
    this.elementType,
    this.enabled = false,
    this.onClickAction,
    this.columnIndex,
    this.rowIndex,
    this.dialogName,
    this.imageId,
    this.isCapacitySelectable,
    this.isCloseable = false,
    this.closedAt,
    this.deletedAt,
    this.isOfficial = false,
    this.createdBy,
    this.parentId,
    this.rootLocationId,
    this.children = const [],
    this.dialogId,
  });

  Location.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        emoji = json['emoji'],
        dialogName = json['dialog_name'],
        elementType = json['element_type'] != null
            ? ElementType.fromJson(json['element_type'])
            : null,
        enabled = json['enabled'] ?? true,
        onClickAction = json['on_click_action'] != null
            ? OnClickAction.fromJson(json['on_click_action'])
            : null,
        columnIndex = json['column_index'],
        rowIndex = json['row_index'],
        imageId = json['image_id'],
        deletedAt = json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at']).toLocal()
            : null,
        isCapacitySelectable = json['is_capacity_selectable'],
        isCloseable = json['is_closeable'] ?? false,
        closedAt = json['closed_at'] != null
            ? DateTime.parse(json['closed_at']).toLocal()
            : null,
        isOfficial = json['is_official'] ?? false,
        createdBy = json['created_by'],
        parentId = json['parent_id'],
        rootLocationId = json['root_location_id'],
        dialogId = json['dialog_id'],
        children = (json['children'] ?? [])
            .map<Location>((e) => Location.fromJson(e))
            .toList();

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'dialog_name': dialogName,
    'element_type': elementType?.name,
    'enabled': enabled,
    'on_click_action': onClickAction?.name,
    'column_index': columnIndex,
    'row_index': rowIndex,
    'is_capacity_selectable': isCapacitySelectable,
    'image_id': imageId,
    'is_official': isOfficial,
    'is_closeable': isCloseable,
    'created_by': createdBy,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
    'parent_id': parentId,
    'root_location_id': rootLocationId,
    'dialog_settings_id': dialogId,
  };
}

enum ElementType {
  root,
  expansionTile,
  listTile,
  card;

  static ElementType fromJson(String json) => values.byName(json);
}

enum OnClickAction {
  openDialog,
  select;

  static OnClickAction fromJson(String json) => values.byName(json);
}