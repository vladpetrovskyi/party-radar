import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/post_service.dart';

class ShareLocationDialog extends StatefulWidget {
  const ShareLocationDialog(
      {super.key,
        required this.onCurrentLocationChanged,
        required this.locationId});

  final Function() onCurrentLocationChanged;
  final int locationId;

  @override
  State<ShareLocationDialog> createState() => _ShareLocationDialogState();
}

class _ShareLocationDialogState extends State<ShareLocationDialog> {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Share location'),
          content: const Text(
              'Would you like to share the selected location as your current in your feed?'),
          actions: <Widget>[
            ElevatedButton(
              child: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                _postLocation(widget.locationId);
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.check),
            ),
          ],
        );
      },
    );
  }

  void _postLocation(int locationId) {
    PostService
        .createPost(locationId, PostType.ongoing)
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your current location has been posted'),
        ),
      );
      widget.onCurrentLocationChanged();
    });
  }
}