import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/dialogs/location_selection_dialog.dart';
import 'package:party_radar/location/dialogs/builders/share_location_dialog_builder.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

class LocationCard extends StatelessWidget with ShareLocationDialogBuilder {
  const LocationCard(
      {super.key, required this.location, required this.onChangedLocation, this.isSelected = false});

  final Location location;
  final Function() onChangedLocation;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: isSelected
          ? RoundedRectangleBorder(
              side: BorderSide(color: Colors.blueGrey.shade300, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(10)))
          : null,
      child: InkWell(
        onTap: () {
          if (location.onClickAction == OnClickAction.openDialog) {
            showDialog<void>(
                context: context,
                builder: (context) {
                  return LocationSelectionDialog(
                    context: context,
                    locations: location.children,
                    dialogName: location.dialogName,
                    imageId: location.imageId,
                    parentLocationId: location.id,
                    onChangedLocation: onChangedLocation,
                  );
                });
          } else {
            buildShareLocationDialog(context, location.id);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: Text(
                    location.emoji != null
                        ? "${location.emoji}\n${location.name}"
                        : location.name,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5, top: 10),
                  child: UserDotsWidget(
                    locationId: location.id,
                    alignment: WrapAlignment.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Function() get onLocationChanged => onChangedLocation;
}
