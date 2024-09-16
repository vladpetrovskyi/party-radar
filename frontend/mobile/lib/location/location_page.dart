import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/location_widget.dart';
import 'package:party_radar/location/widgets/actions_widget.dart';
import 'package:party_radar/location/widgets/drawer.dart';
import 'package:provider/provider.dart';

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
      body: const LocationWidget(),
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
            return TextFormField(
              initialValue: provider.rootLocation?.name,
              onFieldSubmitted: (val) {
                var rootLocation = provider.rootLocation;
                if (rootLocation != null && rootLocation.name != val) {
                  rootLocation.name = val;
                  LocationService.updateLocation(rootLocation).then((updated) =>
                      provider.loadRootLocation(reloadCurrent: true));
                }
              },
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
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
                AddLocationFloatingActionButton(
                    rootLocationId: rootLocationId,
                    elementType: ElementType.listTile,
                    heroTag: "btn1",
                    label: "Select"),
                AddLocationFloatingActionButton(
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

class AddLocationFloatingActionButton extends StatelessWidget {
  const AddLocationFloatingActionButton({
    super.key,
    required this.heroTag,
    required this.elementType,
    this.rootLocationId,
    required this.label,
  });

  final String heroTag;
  final ElementType elementType;
  final int? rootLocationId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: () {
        LocationService.createLocation(
          Location(
            name: "",
            elementType: elementType,
            rootLocationId: rootLocationId,
            parentId: rootLocationId,
          ),
        ).then((_) {
          Provider.of<LocationProvider>(context, listen: false)
              .loadRootLocation(reloadCurrent: true);
        });
      },
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}

class PartyStateDialog extends StatelessWidget {
  const PartyStateDialog({
    super.key,
    required this.onAccept,
    required this.title,
    required this.content,
  });

  final Function() onAccept;
  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        buttonPadding: const EdgeInsets.all(5),
        title: Text(title),
        content: content,
        actions: <Widget>[
          ElevatedButton(
            child: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
          ),
        ],
      );
    });
  }
}
