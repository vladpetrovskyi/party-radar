import 'package:flutter/material.dart';
import 'package:party_radar/screens/location/scheme/tile/dialogs/share_location_dialog_builder.dart';
import 'package:party_radar/screens/location/scheme/tile/widgets/abstract_location_tile.dart';

class DefaultListTile extends AbstractLocationListTile
    with ShareLocationDialogBuilder {
  const DefaultListTile({
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
