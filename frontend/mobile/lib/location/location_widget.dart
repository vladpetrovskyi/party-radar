import 'dart:core';

import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/widgets/location_tile.dart';
import 'package:provider/provider.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget(this.rootLocation, {super.key});

  final Location? rootLocation;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 500),
        () => Provider.of<LocationProvider>(context, listen: false)
            .updateLocation(rootLocation?.id),
      ),
      child: FutureBuilder(
        future: LocationService.getLocationChildren(rootLocation?.id),
        builder:
            (BuildContext context, AsyncSnapshot<List<Location>?> snapshot) {
          if (snapshot.hasError) {
            return const Text("Could not load locations");
          }
          if (snapshot.hasData) {
            return ListView(
              children: _getChildrenOfLocation(snapshot.data),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  List<Widget> _getChildrenOfLocation(List<Location>? rootChildren) {
    if (rootChildren == null || rootChildren.isEmpty) return List.empty();

    List<Widget> resultList = [];

    for (int i = 0; i < rootChildren.length; i++) {
      Location rootChild = rootChildren[i];
      if (rootChild.elementType == ElementType.listTile ||
          rootChild.elementType == ElementType.expansionTile) {
        resultList.add(
          LocationTile(location: rootChild),
        );
      }
    }
    return resultList;
  }
}
