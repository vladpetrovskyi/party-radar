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
