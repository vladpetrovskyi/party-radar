import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class AddLocationButton extends StatelessWidget {
  const AddLocationButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => PartyStateDialog(
          onAccept: () => _createNewRootLocation(context),
          title: "Create new location",
          content: _getContentOfCreateNewLocationDialog(),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [Icon(Icons.add), SizedBox(width: 3), Text("Add new")],
      ),
    );
  }

  void _createNewRootLocation(BuildContext context) =>
      LocationService.createLocation(
        Location(
          name: controller.value.text,
          elementType: ElementType.root,
          enabled: false,
        ),
      ).then((val) {
        var locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        locationProvider
            .loadRootLocation(locationId: val?.id)
            .then((_) => locationProvider.setEditMode(true));
        Navigator.of(context).pop();
      });

  Widget _getContentOfCreateNewLocationDialog() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Please provide a name for your new location"),
          const SizedBox(height: 12),
          Form(
            child: TextFormField(
              controller: controller,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                label: Text('Name'),
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      );
}
