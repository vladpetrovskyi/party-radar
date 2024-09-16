import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/widgets/party_state_dialog.dart';
import 'package:party_radar/screens/location/scheme/tiles/editable_location_list_tile.dart';
import 'package:party_radar/screens/location/scheme/card/card.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class LocationExpansionTile extends EditableLocationListTile {
  const LocationExpansionTile({
    super.key,
    required super.location,
    required super.locationProvider,
    required super.title,
    super.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController newLocationNameFieldController =
        TextEditingController();

    return ExpansionTile(
      onExpansionChanged: (expanded) => expanded
          ? locationProvider.lastOpenedExpansions.add(location.id)
          : locationProvider.lastOpenedExpansions.remove(location.id),
      initiallyExpanded:
          locationProvider.lastOpenedExpansions.contains(location.id),
      title: getTitle(),
      subtitle: getSubtitle(),
      trailing: getTrailing(),
      children: [
        FutureBuilder(
          future: LocationService.getLocationChildren(location.id,
              visibleOnly: true),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Could not build locations, an error occurred");
            }
            if (snapshot.hasData) {
              return _getGridView(
                  snapshot.data!, newLocationNameFieldController);
            }
            return const CircularProgressIndicator();
          },
        )
      ],
    );
  }

  Widget _getGridView(List<Location> locationChildren,
          TextEditingController newLocationNameFieldController) =>
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2.0,
          childAspectRatio: 1.5,
        ),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(10.0),
        itemCount: isEditMode
            ? (locationChildren.length + 1)
            : locationChildren.length,
        itemBuilder: (context, index) {
          if (isEditMode && index == locationChildren.length) {
            return EditableLocationCard(
                newLocationNameFieldController: newLocationNameFieldController,
                rootLocationId: location.rootLocationId!,
                parentId: location.id!);
          }

          var locationChild = locationChildren[index];

          if (locationChild.deletedAt == null &&
              ((!isEditMode && locationChild.enabled) || isEditMode)) {
            return LocationCard(
              location: locationChildren[index],
              isEditMode: isEditMode,
            );
          }
          return null;
        },
      );

  @override
  Widget? getTrailing() => isEditMode
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [const Icon(Icons.arrow_drop_down), popupMenu],
        )
      : null;
}

class EditableLocationCard extends StatelessWidget {
  const EditableLocationCard(
      {super.key,
      required this.newLocationNameFieldController,
      required this.rootLocationId,
      required this.parentId});

  final TextEditingController newLocationNameFieldController;
  final int rootLocationId;
  final int parentId;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => PartyStateDialog(
            onAccept: () {
              LocationService.createLocation(
                Location(
                  name: newLocationNameFieldController.text,
                  elementType: ElementType.card,
                  rootLocationId: rootLocationId,
                  parentId: parentId,
                ),
              ).then((_) =>
                  Provider.of<LocationProvider>(context, listen: false)
                      .loadRootLocation(reloadCurrent: true));
            },
            title: "Add location card",
            content: _createNewLocationDialogContent(),
          ),
        ),
        child: _buildCardName(),
      ),
    );
  }

  Widget _buildCardName() => const Padding(
        padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 5),
        child: Icon(Icons.add),
      );

  Widget _createNewLocationDialogContent() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Please provide a name for your new location card"),
          const SizedBox(height: 12),
          Form(
            child: TextFormField(
              controller: newLocationNameFieldController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                label: Text('Name'),
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      );
}
