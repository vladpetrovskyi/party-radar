import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/default/default_list_tile.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/expansion_tile.dart';
import 'package:provider/provider.dart';

class LocationTile extends StatefulWidget {
  const LocationTile({super.key, required this.location});

  final Location location;

  @override
  State<LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<LocationTile> {
  late Location _location;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
  }

  @override
  Widget build(BuildContext context) {
    var locationProvider = Provider.of<LocationProvider>(context, listen: true);
    var isEditMode = locationProvider.editMode;

    if (_location.elementType == ElementType.listTile ||
        (_location.elementType == ElementType.expansionTile &&
            !_location.enabled &&
            !isEditMode)) {
      return DefaultListTile(
        location: _location,
        locationProvider: locationProvider,
        isEditMode: isEditMode,
        title: _buildTitle(locationProvider),
      );
    }
    if (_location.elementType == ElementType.expansionTile) {
      return LocationExpansionTile(
        location: _location,
        locationProvider: locationProvider,
        title: _buildTitle(locationProvider),
        isEditMode: isEditMode,
      );
    }
    return Container();
  }

  Text _buildTitle(LocationProvider provider) {
    var containsSelectedLocation =
        provider.currentLocationTree.contains(_location.id);

    return Text(
      _location.emoji != null
          ? "${_location.emoji} ${_location.name}"
          : _location.name,
      style: TextStyle(
        fontSize: 28,
        color: containsSelectedLocation
            ? Theme.of(context).colorScheme.primary
            : null,
        fontWeight: containsSelectedLocation ? FontWeight.bold : null,
      ),
    );
  }
}
