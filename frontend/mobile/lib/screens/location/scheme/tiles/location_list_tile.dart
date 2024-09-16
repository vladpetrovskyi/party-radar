import 'package:flutter/material.dart';
import 'package:party_radar/screens/location/scheme/share_location_dialog_builder.dart';
import 'package:party_radar/screens/location/scheme/tiles/editable_location_list_tile.dart';

class LocationListTile extends EditableLocationListTile
    with ShareLocationDialogBuilder {
  const LocationListTile({
    super.key,
    required super.location,
    required super.locationProvider,
    super.isEditMode,
    required super.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: isEditMode ? true : location.enabled,
      onTap: getOnTapFunction(context),
      title: getTitle(),
      subtitle: getSubtitle(),
      trailing: getTrailing(),
    );
  }

  Function() getOnTapFunction(BuildContext context) =>
      () => isEditMode ? null : buildShareLocationDialog(context, location.id);
}
