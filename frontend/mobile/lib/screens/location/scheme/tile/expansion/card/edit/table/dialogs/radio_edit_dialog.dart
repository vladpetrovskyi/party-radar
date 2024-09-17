import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';

class RadioEditDialog extends StatefulWidget {
  const RadioEditDialog({
    super.key,
    required this.location,
    required this.onUpdate,
  });

  final VoidCallback onUpdate;
  final Location location;

  @override
  State<RadioEditDialog> createState() => _RadioEditDialogState();
}

class _RadioEditDialogState extends State<RadioEditDialog>
    with ErrorSnackBar {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit radio button'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Location name',
              border: OutlineInputBorder(),
            ),
          ),
          // TODO: "enabled" should also be considered when building card dialog (dialog_radios.dart);
          // TODO: also the border around should be grey when not enabled
          // const SizedBox(height: 12),
          // SwitchListTile(
          //   value: widget.location.enabled,
          //   onChanged: (newVal) {
          //     widget.location.enabled = newVal;
          //     LocationService.updateLocation(widget.location)
          //         .then((_) => setState(() {}));
          //   },
          //   title: const Text("Enabled"),
          // ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        ElevatedButton(
          onPressed: () => _deleteLocation(),
          child: const Icon(Icons.delete_outline),
        ),
        ElevatedButton(
          onPressed: () => _updateLocationName(),
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  _updateLocationName() {
    widget.location.name = _nameController.text;
    LocationService.updateLocation(widget.location).then((updated) {
      if (updated == null) {
        showErrorSnackBar("Error occurred, please try again", context);
        return;
      }
      widget.onUpdate();
    });
    Navigator.of(context).pop();
  }

  _deleteLocation() {
    LocationService.deleteLocation(widget.location.id!).then((deleted) {
      if (!deleted) {
        showErrorSnackBar("Error occurred, please try again", context);
        return;
      }
      widget.onUpdate();
    });
    Navigator.of(context).pop();
  }
}