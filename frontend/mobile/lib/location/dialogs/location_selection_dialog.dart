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
  });

  final BuildContext context;
  final List<Location> locations;
  final String? dialogName;
  final int? imageId;
  final Function() onChangedLocation;
  final int parentLocationId;

  @override
  State<LocationSelectionDialog> createState() =>
      _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
  int? selectedRadio;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        buttonPadding: const EdgeInsets.all(5),
        title: Text(widget.dialogName ?? ''),
        content: Column(
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
                  return const CircularProgressIndicator();
                },
              ),
            const SizedBox(height: 10),
            DialogRadiosWidget(
              locations: widget.locations,
              onChangeSelectedRadio: (locationId) => setState(() {
                selectedRadio = locationId;
              }),
              selectedRadio: selectedRadio,
            )
          ],
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    selectedRadio = null;
                    Navigator.of(context).pop();
                  },
            child: const Icon(Icons.close),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      selectedRadio = null;
                    });
                  },
            child: const Icon(Icons.delete_forever_outlined),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : _isRegistrationFinished()
                    ? () {
                        _postLocation(selectedRadio ?? widget.parentLocationId);
                        Navigator.of(context).pop();
                      }
                    : null,
            child: const Icon(Icons.check),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    });
  }

  bool _isRegistrationFinished() {
    return (FirebaseAuth.instance.currentUser!.emailVerified ||
            FlavorConfig.instance.flavor != Flavor.prod) &&
        FirebaseAuth.instance.currentUser!.displayName != null;
  }

  void _postLocation(int locationId) {
    setState(() {
      _isLoading = true;
    });
    PostService.createPost(locationId, PostType.ongoing).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your current location has been posted'),
        ),
      );
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
