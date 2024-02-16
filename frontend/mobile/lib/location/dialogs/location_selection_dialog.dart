import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/widgets/dialog_radios.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:party_radar/common/services/post_service.dart';
import 'package:widget_zoom/widget_zoom.dart';

class LocationSelectionDialog extends StatefulWidget {
  const LocationSelectionDialog({
    super.key,
    required this.context,
    required this.locations,
    this.dialogName,
    this.imageId,
    required this.parentLocationId,
    required this.onChangedLocation,
    this.isCapacitySelectable,
  });

  final BuildContext context;
  final List<Location> locations;
  final String? dialogName;
  final int? imageId;
  final Function() onChangedLocation;
  final int parentLocationId;
  final bool? isCapacitySelectable;

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
                  future: ImageService.getImage(widget.imageId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return WidgetZoom(
                          heroAnimationTag: 'tag', zoomWidget: snapshot.data!);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              const SizedBox(height: 10),
              DialogRadiosWidget(
                locations: widget.locations,
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
              icon: Icons.delete_forever_outlined,
              onPressedFunction: () => setState(() {
                selectedRadio = null;
                _currentSliderValue = null;
              })),
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

    PostService.createPost(locationId, PostType.ongoing, _currentSliderValue?.round()).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your current location has been posted'),
        ),
      );
      Navigator.of(context).pop();
      widget.onChangedLocation();
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
