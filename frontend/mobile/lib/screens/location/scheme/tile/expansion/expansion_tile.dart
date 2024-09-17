import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/card.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/editable_card.dart';
import 'package:party_radar/screens/location/scheme/tile/widgets/abstract_location_tile.dart';
import 'package:party_radar/services/location_service.dart';

class LocationExpansionTile extends AbstractLocationListTile {
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
