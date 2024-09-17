import 'package:flutter/material.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:provider/provider.dart';

class ShareLocationDialog extends StatefulWidget {
  const ShareLocationDialog({
    super.key,
    required this.locationId,
  });

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
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: const Icon(Icons.close),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
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
    setState(() => _isLoading = true);
    PostService.createPost(locationId, PostType.ongoing, null).then((value) {
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
