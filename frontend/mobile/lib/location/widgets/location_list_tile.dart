import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/dialogs/builders/share_location_dialog_builder.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

class LocationListTile extends StatelessWidget with ShareLocationDialogBuilder {
  const LocationListTile(
      {super.key, required this.onChangedLocation, required this.location});

  final Function() onChangedLocation;
  final Location location;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: location.enabled,
      onTap: () {
        buildShareLocationDialog(context, location.id);
      },
      title: Text(
        location.emoji != null
            ? "${location.emoji} ${location.name}"
            : location.name,
        style: const TextStyle(
          fontSize: 28,
          // fontWeight: FontWeight.bold,
        ),
      ),
      subtitle:
      location.enabled ? UserDotsWidget(locationId: location.id) : null,
    );
  }

  @override
  Function() get onLocationChanged => onChangedLocation;
}