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