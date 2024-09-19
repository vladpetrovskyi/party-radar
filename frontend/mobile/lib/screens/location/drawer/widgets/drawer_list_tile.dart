import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class DrawerListTile extends StatelessWidget with ErrorSnackBar {
  const DrawerListTile({
    super.key,
    required this.location,
    required this.onUpdate,
  });

  final Location location;
  final Function onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: title,
      subtitle: subtitle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () => _selectLocation(location.id, context),
      onLongPress: () => showDialog(
        context: context,
        builder: (context) => PartyStateDialog(
          title: 'Delete location',
          content: const Text(
              'Are you sure you would like to delete this location? This action cannot be reversed!'),
          onAccept: () => _deleteLocation(context),
        ),
      ),
      trailing: location.createdBy ==
              Provider.of<UserProvider>(context, listen: false).user?.username
          ? Switch(
              value: location.enabled,
              onChanged: (value) {
                location.enabled = value;
                var snackBarText =
                    "Location is now ${value ? 'visible' : 'invisible'} for all users";
                LocationService.updateLocation(location).then((_) {
                  onUpdate();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(snackBarText)));
                });
              },
            )
          : null,
    );
  }

  Widget get title => Row(
        children: [
          Text(
            location.name,
            style: const TextStyle(fontSize: 18),
          ),
          if (location.isOfficial) const SizedBox(width: 5),
          if (location.isOfficial)
            const Icon(IconData(0xe699, fontFamily: 'MaterialIcons'))
        ],
      );

  Widget? get subtitle =>
      location.createdBy != null ? Text("by ${location.createdBy}") : null;

  void _selectLocation(int? locationId, BuildContext context) async {
    if (locationId == null) return;

    var locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.editMode = false;
    locationProvider.loadRootLocation(locationId: locationId);

    Navigator.of(context).pop();
  }

  void _deleteLocation(BuildContext context) {
    var locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    LocationService.deleteLocation(location.id).then((deleted) {
      if (deleted) {
        onUpdate();
        if (locationProvider.rootLocation?.id == location.id) {
          locationProvider.updateRootLocation(null);
        }
      }
    });
  }
}
