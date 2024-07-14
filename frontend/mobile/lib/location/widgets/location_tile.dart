import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/location/widgets/location_expansion_tile.dart';
import 'package:party_radar/location/widgets/location_list_tile.dart';
import 'package:provider/provider.dart';

class LocationTile extends StatefulWidget {
  const LocationTile({super.key, required this.location});

  final Location location;

  @override
  State<LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<LocationTile> {
  late Location _location;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    _textEditingController = TextEditingController(text: widget.location.name);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget title = Consumer<UserProvider>(
        builder: (BuildContext context, UserProvider provider, Widget? child) =>
            _buildTitle(context, provider));

    return Consumer<LocationProvider>(
      builder: (BuildContext context, LocationProvider locationProvider,
          Widget? child) {
        if (_location.elementType == ElementType.listTile) {
          return LocationListTile(
            location: _location,
            textEditingController: _textEditingController,
            isEditMode: locationProvider.editMode,
            title: title,
          );
        }
        if (_location.elementType == ElementType.expansionTile) {
          return LocationExpansionTile(
            location: _location,
            title: title,
            isEditMode: locationProvider.editMode,
            textEditingController: _textEditingController,
          );
        }
        return Container();
      },
    );
  }

  Text _buildTitle(BuildContext context, UserProvider userProvider) {
    var containsSelectedLocation =
        userProvider.currentLocationTree.contains(_location.id);
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
