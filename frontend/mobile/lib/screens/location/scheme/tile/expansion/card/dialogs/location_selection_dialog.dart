import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:provider/provider.dart';
import 'package:widget_zoom/widget_zoom.dart';

class LocationSelectionDialog extends StatefulWidget {
  const LocationSelectionDialog({
    super.key,
    required this.context,
    this.dialogName,
    this.imageId,
    required this.parentLocationId,
    required this.locationChildren,
    this.isCapacitySelectable,
  });

  final BuildContext context;
  final String? dialogName;
  final int? imageId;
  final int parentLocationId;
  final bool? isCapacitySelectable;
  final List<Location> locationChildren;

  @override
  State<LocationSelectionDialog> createState() =>
      _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
  int? selectedRadio;
  bool _isLoading = false;
  double? _currentSliderValue;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        buttonPadding: const EdgeInsets.all(5),
        title: Text(widget.dialogName ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.imageId != null)
                FutureBuilder(
                  future: ImageService.get(widget.imageId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return WidgetZoom(
                          heroAnimationTag: 'tag', zoomWidget: snapshot.data!);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              const SizedBox(height: 10),
              _DialogRadiosWidget(
                locations: widget.locationChildren,
                onChangeSelectedRadio: (locationId) =>
                    setState(() => selectedRadio = locationId),
                selectedRadio: selectedRadio,
              ),
              if (widget.isCapacitySelectable ?? false)
                Slider(
                  value: _currentSliderValue ?? 0,
                  max: 10,
                  divisions: 10,
                  label:
                      ' Free spots: ${(_currentSliderValue ?? 0.0).round().toString()} ',
                  onChanged: (double value) {
                    setState(() {
                      _currentSliderValue = value;
                    });
                  },
                )
            ],
          ),
        ),
        actions: <Widget>[
          _getLoadingButton(
              icon: Icons.close,
              onPressedFunction: () {
                selectedRadio = null;
                Navigator.of(context).pop();
              }),
          _getLoadingButton(
              icon: Icons.check,
              onPressedFunction: _isRegistrationFinished()
                  ? () =>
                      _postLocation(selectedRadio ?? widget.parentLocationId)
                  : () {}),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    });
  }

  Widget _getLoadingButton({
    required IconData icon,
    required Function() onPressedFunction,
  }) =>
      ElevatedButton(
        onPressed: _isLoading ? null : onPressedFunction,
        child: Icon(icon),
      );

  bool _isRegistrationFinished() =>
      (FirebaseAuth.instance.currentUser!.emailVerified ||
          FlavorConfig.instance.flavor != Flavor.prod) &&
      FirebaseAuth.instance.currentUser!.displayName != null;

  void _postLocation(int locationId) {
    setState(() => _isLoading = true);

    PostService.createPost(
            locationId, PostType.ongoing, _currentSliderValue?.round())
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your current location has been posted'),
        ),
      );
      Provider.of<UserProvider>(context, listen: false).updateUser();
      Provider.of<LocationProvider>(context, listen: false)
          .loadCurrentLocationTree();
      Navigator.of(context).pop();
    }).onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Could not post your location',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.of(context).pop();
    });
  }
}

class _DialogRadiosWidget extends StatelessWidget {
  const _DialogRadiosWidget({
    required this.locations,
    required this.onChangeSelectedRadio,
    required this.selectedRadio,
  });

  final List<Location> locations;
  final Function(int?) onChangeSelectedRadio;
  final int? selectedRadio;

  @override
  Widget build(BuildContext context) {
    locations
        .sort((a, b) => (a.columnIndex ?? 0).compareTo(b.columnIndex ?? 0));

    List<List<_RadioListTileWidget>> columnList =
        List.generate((locations.last.columnIndex ?? 0) + 1, (index) => []);
    for (int i = 0; i < locations.length; i++) {
      columnList.elementAt(locations[i].columnIndex ?? 0).add(
            _RadioListTileWidget(
              locationId: locations[i].id!,
              locationName: locations[i].name,
              selectedValue: selectedRadio,
              onChanged: onChangeSelectedRadio,
              locationRowIndex: locations[i].rowIndex ?? 0,
            ),
          );
    }

    columnList.removeWhere((col) => col.isEmpty);

    List<Column> columns = [];

    for (List<_RadioListTileWidget> columnChildren in columnList) {
      columnChildren
          .sort((a, b) => a.locationRowIndex.compareTo(b.locationRowIndex));
      columns.add(Column(children: [...columnChildren]));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [...columns],
    );
  }
}

class _RadioListTileWidget extends StatelessWidget {
  const _RadioListTileWidget({
    required this.locationId,
    required this.locationName,
    required this.selectedValue,
    required this.locationRowIndex,
    this.onChanged,
  });

  final int locationId;
  final String locationName;
  final int? selectedValue;
  final Function(int? id)? onChanged;
  final int locationRowIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Radio(
          visualDensity: const VisualDensity(
            horizontal: VisualDensity.minimumDensity,
            vertical: VisualDensity.minimumDensity,
          ),
          value: locationId,
          groupValue: selectedValue,
          onChanged: onChanged,
          toggleable: true,
        ),
        Text(locationName),
      ],
    );
  }
}
