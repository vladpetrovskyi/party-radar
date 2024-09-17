import 'package:party_radar/models/user.dart';

class Friendship {
  final int id;
  final User friend;
  final FriendshipStatus? status;

  Friendship({required this.id, required this.friend, this.status});

  Friendship.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        friend = User(
          id: json['user_id'],
          username: json['username'],
          imageId: json['image_id'],
          locationName: json['location'],
        ),
        status = json['status'] != null ? FriendshipStatus.fromJson(json['status']) : null;
}

enum FriendshipStatus {
  requested,
  accepted,
  rejected;

  static FriendshipStatus fromJson(String json) => values.byName(json);
}
