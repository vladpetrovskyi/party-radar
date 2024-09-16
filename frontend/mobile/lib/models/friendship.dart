import 'package:party_radar/models/user.dart';

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

enum FriendshipStatus {
  requested,
  accepted,
  rejected;

  static FriendshipStatus fromJson(String json) => values.byName(json);
}