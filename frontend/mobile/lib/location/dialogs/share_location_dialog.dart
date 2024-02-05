import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/post_service.dart';

class ShareLocationDialog extends StatefulWidget {
  const ShareLocationDialog({
    super.key,
    required this.onCurrentLocationChanged,
    required this.locationId,
  });

  final Function() onCurrentLocationChanged;
  final int locationId;

  @override
  State<ShareLocationDialog> createState() => _ShareLocationDialogState();
}

class _ShareLocationDialogState extends State<ShareLocationDialog> {
  bool _isLoading = false;

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
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.close),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                _postLocation(widget.locationId);
              },
              child: const Icon(Icons.check),
            ),
          ],
        );
      },
    );
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
      widget.onCurrentLocationChanged();
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
