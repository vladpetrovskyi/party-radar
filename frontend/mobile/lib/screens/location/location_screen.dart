import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/app_bar/app_bar.dart';
import 'package:party_radar/screens/location/drawer/location_drawer.dart';
import 'package:party_radar/screens/location/scheme/location_scheme.dart';
import 'package:party_radar/screens/location/widgets/add_location_fab.dart';
import 'package:provider/provider.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: floatingActionButtons,
      appBar: getAppBar(context),
      drawer: const LocationDrawer(),
      body: const LocationScheme(),
    );
  }

  Widget get floatingActionButtons => Selector<LocationProvider, bool>(
        selector: (_, provider) => provider.editMode,
        builder: (context, editMode, __) {
          if (editMode) {
            var rootLocationId =
                Provider.of<LocationProvider>(context, listen: false)
                    .rootLocation
                    ?.id;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AddLocationFAB(
                    rootLocationId: rootLocationId,
                    elementType: ElementType.listTile,
                    heroTag: "btn1",
                    label: "Select"),
                AddLocationFAB(
                    rootLocationId: rootLocationId,
                    elementType: ElementType.expansionTile,
                    heroTag: "btn2",
                    label: "Dropdown"),
              ],
            );
          }
          return Container();
        },
      );
}
