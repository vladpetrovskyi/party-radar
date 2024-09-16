import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/widgets/actions_widget.dart';
import 'package:party_radar/screens/location/widgets/add_location_fab.dart';
import 'package:party_radar/screens/location/location_drawer.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

import 'scheme/location_scheme.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: floatingActionButtons,
      appBar: AppBar(
        centerTitle: true,
        title: title,
        actions: actions,
      ),
      drawer: const LocationDrawer(),
      body: const LocationScheme(),
    );
  }

  List<Widget> get actions => [
        Consumer2<UserProvider, LocationProvider>(
          builder: (context, userProvider, locationProvider, child) {
            if (locationProvider.rootLocation == null) {
              return Container();
            }

            return ActionsWidget(
              userProvider: userProvider,
              locationProvider: locationProvider,
            );
          },
        )
      ];

  Widget get title => Consumer<LocationProvider>(
        builder: (_, provider, __) {
          if (provider.editMode) {
            final TextEditingController controller =
                TextEditingController(text: provider.rootLocation?.name);
            return TextFormField(
              controller: controller,
              onFieldSubmitted: (val) => _updateTitle(val, provider),
              onTapOutside: (_) {
                _updateTitle(controller.text, provider);
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: const TextStyle(
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(119, 136, 153, 0.05),
                border: UnderlineInputBorder(),
                isCollapsed: true,
              ),
            );
          }

          return SizedBox(
            height: 40,
            child: Hero(
              tag: 'logo_hero',
              child: Image.asset('assets/logo_app_bar.png'),
            ),
          );
        },
      );

  void _updateTitle(String newTitle, LocationProvider provider) {
    var rootLocation = provider.rootLocation;
    if (rootLocation != null && rootLocation.name != newTitle) {
      rootLocation.name = newTitle;
      LocationService.updateLocation(rootLocation)
          .then((updated) => provider.loadRootLocation(reloadCurrent: true));
    }
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
