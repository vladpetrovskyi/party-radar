import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class DrawerListTile extends StatelessWidget with ErrorSnackBar {
  const DrawerListTile(
      {super.key, required this.location, required this.onUpdate});

  final Location location;
  final Function onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: _listTileTitle(location),
      subtitle: _listTileSubtitle(location),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () => _selectLocation(location.id, context),
      trailing: location.createdBy ==
              Provider.of<UserProvider>(context, listen: false).user?.username
          ? Switch(
              value: location.enabled,
              onChanged: (value) {
                location.enabled = value;
                LocationService.updateLocation(location)
                    .then((_) => onUpdate());
              },
            )
          : null,
    );
  }

  Widget _listTileTitle(Location location) => Row(
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

  Widget? _listTileSubtitle(Location location) =>
      location.createdBy != null ? Text("by ${location.createdBy}") : null;

  void _selectLocation(int? locationId, BuildContext context) async {
    if (locationId == null) return;

    if (FirebaseAuth.instance.currentUser?.displayName == null ||
        FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      showErrorSnackBar('Please select username first', context);
    }

    var locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.editMode = false;
    locationProvider.loadRootLocation(locationId: locationId);

    Navigator.of(context).pop();
  }
}
