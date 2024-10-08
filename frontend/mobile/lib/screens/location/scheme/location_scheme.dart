import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/location_tile.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class LocationScheme extends StatelessWidget {
  const LocationScheme({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (_, provider, __) {
        if (provider.rootLocation != null) {
          return RefreshIndicator(
            onRefresh: () => Future.delayed(
              const Duration(milliseconds: 500),
                  () {
                provider.loadCurrentLocationTree();
                provider.loadRootLocation(reloadCurrent: true);
              },
            ),
            child: FutureBuilder(
              future: LocationService.getLocationChildren(
                  provider.rootLocation?.id),
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Could not load locations");
                }
                if (snapshot.hasData) {
                  return ListView(
                    children: _buildLocationChildrenList(snapshot.data),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          );
        }

        return const Center(
          child: Text(
            'Please select a location in the upper left menu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28),
          ),
        );
      },
    );
  }

  List<Widget> _buildLocationChildrenList(List<Location>? rootChildren) {
    if (rootChildren == null || rootChildren.isEmpty) return List.empty();

    List<Widget> resultList = [];

    for (int i = 0; i < rootChildren.length; i++) {
      Location rootChild = rootChildren[i];
      if (rootChild.elementType == ElementType.listTile ||
          rootChild.elementType == ElementType.expansionTile) {
        resultList.add(
          LocationTile(key: UniqueKey(), location: rootChild),
        );
      }
    }
    return resultList;
  }
}