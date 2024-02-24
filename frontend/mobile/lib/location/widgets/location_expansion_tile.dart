import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/widgets/location_card.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

class LocationExpansionTile extends StatelessWidget {
  const LocationExpansionTile({
    super.key,
    required this.location,
    required this.onChangedLocation,
    this.currentUserLocationId,
    this.canPostUpdates = false,
  });

  final Location location;
  final Function() onChangedLocation;
  final int? currentUserLocationId;
  final bool canPostUpdates;

  @override
  Widget build(BuildContext context) {
    List visibleLocationChildren = location.children
        .where((element) => element.deletedAt == null)
        .toList();
    return ExpansionTile(
      title: _buildTitle(context),
      subtitle: UserDotsWidget(locationId: location.id),
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2.0,
            childAspectRatio: 1.5,
          ),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          itemCount: visibleLocationChildren.length,
          itemBuilder: (context, index) {
            if (visibleLocationChildren[index].deletedAt == null) {
              return LocationCard(
                location: visibleLocationChildren[index],
                onChangedLocation: onChangedLocation,
                isSelected: _checkContainsSelectedLocation(
                    visibleLocationChildren[index]),
                isActive: canPostUpdates,
              );
            }
            return Container();
          },
        )
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    bool containsSelectedLocation = _checkContainsSelectedLocation(location);

    return Text(
      location.emoji != null
          ? "${location.emoji} ${location.name}"
          : location.name,
      style: TextStyle(
        fontSize: 28,
        color: containsSelectedLocation
            ? Theme.of(context).colorScheme.primary
            : null,
        fontWeight: containsSelectedLocation ? FontWeight.bold : null,
      ),
    );
  }

  bool _checkContainsSelectedLocation(Location location) {
    if (location.id == currentUserLocationId) {
      return true;
    }

    for (Location child in location.children) {
      if (child.children.isNotEmpty) {
        if (_checkContainsSelectedLocation(child)) {
          return true;
        }
      } else if (child.id == currentUserLocationId) {
        return true;
      }
    }

    return false;
  }
}

//
