import 'package:flutter/material.dart';
import 'package:party_radar/location/dialogs/builders/share_location_dialog_builder.dart';
import 'package:party_radar/location/widgets/editable_location_list_tile.dart';

class LocationListTile extends EditableLocationListTile
    with ShareLocationDialogBuilder {
  const LocationListTile({
    super.key,
    required super.location,
    super.isEditMode,
    super.textEditingController,
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
