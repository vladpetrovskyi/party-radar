import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:party_radar/common/providers.dart';
import 'package:provider/provider.dart';

import '../../common/models.dart';
import '../../common/services/location_service.dart';
import '../../profile/tabs/widgets/not_found_widget.dart';
import '../location_page.dart';

class LocationDrawer extends StatefulWidget {
  const LocationDrawer({super.key});

  @override
  State<LocationDrawer> createState() => _LocationDrawerState();
}

class _LocationDrawerState extends State<LocationDrawer> {
  final TextEditingController _newLocationNameFieldController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: const Text(
              'Locations menu',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: LocationService.getLocations(ElementType.root),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const NotFoundWidget(
                      title: 'No results',
                      message: 'Locations could not be loaded or found');
                }
                if (snapshot.hasData) {
                  return _getListOfLocations(snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _openDialog(
                    PartyStateDialog(
                      onAccept: () {
                        LocationService.createLocation(
                          Location(
                            name: _newLocationNameFieldController.value.text,
                            elementType: ElementType.root,
                            enabled: false,
                          ),
                        ).then((val) {
                          var locationProvider = Provider.of<LocationProvider>(
                              context,
                              listen: false);
                          locationProvider
                              .loadRootLocation(locationId: val?.id)
                              .then((_) => locationProvider.setEditMode(true));
                          Navigator.of(context).pop();
                        });
                      },
                      title: "Create new location",
                      content: _createNewLocationDialogContent(),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 3),
                      Text("Add new")
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createNewLocationDialogContent() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Please provide a name for your new location"),
          const SizedBox(height: 12),
          Form(
            child: TextFormField(
              controller: _newLocationNameFieldController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                label: Text('Name'),
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      );

  ListView _getListOfLocations(List<Location> locationList) => ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: locationList.length,
        itemBuilder: (context, index) {
          var location = locationList[index];
          return ListTile(
            dense: true,
            title: _listTileTitle(location),
            subtitle: _listTileSubtitle(location),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => _selectLocation(location.id),
            trailing: location.createdBy ==
                    Provider.of<UserProvider>(context, listen: false)
                        .user
                        ?.username
                ? Switch(
                    value: location.enabled,
                    onChanged: (value) {
                      location.enabled = value;
                      LocationService.updateLocation(location)
                          .then((_) => setState(() {}));
                    },
                  )
                : null,
          );
        },
      );

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

  void _openDialog(Widget dialogWidget) {
    showDialog(
        context: context,
        builder: (context) {
          return dialogWidget;
        });
  }

  void _selectLocation(int? locationId) async {
    if (locationId == null) return;

    if (firebase.FirebaseAuth.instance.currentUser?.displayName == null ||
        firebase.FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      _showErrorSnackBar('Please select username first');
    }

    var locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.editMode = false;
    locationProvider.loadRootLocation(locationId: locationId);

    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
