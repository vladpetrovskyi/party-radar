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
  });

  final Location location;
  final Function() onChangedLocation;
  final int? currentUserLocationId;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Text(
            location.emoji != null
                ? "${location.emoji} ${location.name}"
                : location.name,
            style: const TextStyle(
              fontSize: 28,
              // fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5,),
          if (currentUserLocationId == location.id) const Icon(Icons.check),
        ],
      ),
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
          itemCount: location.children.length,
          itemBuilder: (context, post) {
            return LocationCard(
              location: location.children[post],
              onChangedLocation: onChangedLocation,
              isSelected:
                  location.children[post].id == currentUserLocationId,
            );
          },
        )
      ],
    );
  }
}
