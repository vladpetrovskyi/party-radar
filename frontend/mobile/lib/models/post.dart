import 'location.dart';

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

enum PostType {
  start,
  ongoing,
  end;

  static PostType fromJson(String json) => values.byName(json);
}
