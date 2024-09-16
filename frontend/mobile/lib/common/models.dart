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

class DialogSettings {
  int? id;
  String name;
  int? columnsNumber;
  bool isCapacitySelectable = false;
  int locationId;

  DialogSettings({
    this.id,
    this.name = '',
    this.columnsNumber,
    this.isCapacitySelectable = false,
    required this.locationId,
  });

  DialogSettings.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['username'],
        columnsNumber = json['columns_number'],
        isCapacitySelectable = json['is_capacity_selectable'],
        locationId = json['location_id'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'columns_number': columnsNumber,
        'is_capacity_selectable': isCapacitySelectable,
        'location_id': locationId
      };
}

class User {
  int? id;
  String? username;
  int? imageId;
  int? locationId;
  int? rootLocationId;
  String? locationName;

  User({
    this.id,
    this.username,
    this.imageId,
    this.locationId,
    this.rootLocationId,
    this.locationName,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        imageId = json['image_id'],
        locationId = json['current_location_id'],
        rootLocationId = json['current_root_location_id'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'image_id': imageId,
        'current_location_id': locationId,
        'current_root_location_id': rootLocationId,
      };
}

class Post {
  final int? id;
  final String? username;
  final PostType type;
  final DateTime timestamp;
  final Location location;
  final int? imageId;
  final int? views;
  final int? capacity;

  // TODO
  // final String header;
  // final String? subHeader;

  Post({
    this.id,
    this.username,
    required this.type,
    required this.timestamp,
    required this.location,
    this.imageId,
    this.capacity,
    this.views,
  });

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        type = PostType.fromJson(json['post_type']),
        timestamp = DateTime.parse(json['timestamp']).toLocal(),
        location = Location.fromJson(json['location']),
        imageId = json['image_id'],
        capacity = json['capacity'],
        views = json['views'];
}

class Friendship {
  final int id;
  final User friend;

  Friendship({
    required this.id,
    required this.friend,
  });

  Friendship.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        friend = User(
          id: json['user_id'],
          username: json['username'],
          imageId: json['image_id'],
          locationName: json['location'],
        );
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

enum PostType {
  start,
  ongoing,
  end;

  static PostType fromJson(String json) => values.byName(json);
}

enum FriendshipStatus {
  requested,
  accepted,
  rejected;

  static FriendshipStatus fromJson(String json) => values.byName(json);
}
