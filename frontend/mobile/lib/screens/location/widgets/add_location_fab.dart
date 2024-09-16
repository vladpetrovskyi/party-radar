import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class AddLocationFAB extends StatelessWidget {
  const AddLocationFAB({
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
        ).then((_) => Provider.of<LocationProvider>(context, listen: false)
            .loadRootLocation(reloadCurrent: true));
      },
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
