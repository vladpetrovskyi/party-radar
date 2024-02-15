import 'dart:core';

import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/widgets/location_card.dart';
import 'package:party_radar/location/widgets/location_expansion_tile.dart';
import 'package:party_radar/location/widgets/location_list_tile.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({
    super.key,
    required this.club,
    required this.onChangedLocation,
    this.currentUserLocationId,
    this.canPostUpdates = false,
  });

  final Location club;
  final Function() onChangedLocation;
  final int? currentUserLocationId;
  final bool canPostUpdates;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        onChangedLocation();
      },
      child: ListView(
        children: club.elementType == ElementType.root
            ? _getChildrenOfLocation(club.children)
            : [],
      ),
    );
  }

  List<Widget> _getChildrenOfLocation(List<Location>? rootChildren) {
    if (rootChildren == null || rootChildren.isEmpty) return List.empty();

    List<Widget> resultList = [];

    for (int i = 0; i < rootChildren.length; i++) {
      Location rootChild = rootChildren[i];
      if (rootChild.elementType == ElementType.listTile) {
        resultList.add(LocationListTile(
          location: rootChild,
          onChangedLocation: onChangedLocation,
        ));
      } else if (rootChild.elementType == ElementType.expansionTile) {
        resultList.add(LocationExpansionTile(
          location: rootChild,
          onChangedLocation: onChangedLocation,
          currentUserLocationId: currentUserLocationId,
          canPostUpdates: canPostUpdates,
        ));
      } else if (rootChild.elementType == ElementType.card) {
        resultList.add(LocationCard(
          location: rootChild,
          onChangedLocation: onChangedLocation,
          isActive: canPostUpdates,
        ));
      }
    }
    return resultList;
  }
}
