import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/screens/location/drawer/widgets/add_location_button.dart';
import 'package:party_radar/screens/location/drawer/widgets/drawer_list_tile.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:party_radar/widgets/not_found_widget.dart';

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
        children: [
          drawerHeader,
          locationList,
          addLocationButton,
        ],
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
            AddLocationButton(controller: _newLocationNameFieldController),
          ],
        ),
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
