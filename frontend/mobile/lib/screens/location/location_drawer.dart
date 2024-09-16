import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/widgets/drawer_list_tile.dart';
import 'package:party_radar/screens/location/widgets/party_state_dialog.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:party_radar/widgets/not_found_widget.dart';
import 'package:provider/provider.dart';

class LocationDrawer extends StatefulWidget {
  const LocationDrawer({super.key});

  @override
  State<LocationDrawer> createState() => _LocationDrawerState();
}

class _LocationDrawerState extends State<LocationDrawer> with ErrorSnackBar {
  final TextEditingController _newLocationNameFieldController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [drawerHeader, locationList, addLocationButton],
      ),
    );
  }

  Widget get drawerHeader => DrawerHeader(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: const Text(
          'Locations menu',
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
        ),
      );

  Widget get locationList => Expanded(
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
      );

  Widget get addLocationButton => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => PartyStateDialog(
                  onAccept: () => _createNewRootLocation(),
                  title: "Create new location",
                  content: _getContentOfCreateNewLocationDialog(),
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
      );

  void _createNewRootLocation() => LocationService.createLocation(
        Location(
          name: _newLocationNameFieldController.value.text,
          elementType: ElementType.root,
          enabled: false,
        ),
      ).then((val) {
        var locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        locationProvider
            .loadRootLocation(locationId: val?.id)
            .then((_) => locationProvider.setEditMode(true));
        Navigator.of(context).pop();
      });

  Widget _getContentOfCreateNewLocationDialog() => Column(
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
          return DrawerListTile(
              location: location, onUpdate: () => setState(() {}));
        },
      );
}
