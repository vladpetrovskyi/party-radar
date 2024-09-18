import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class EditableLocationCard extends StatefulWidget {
  const EditableLocationCard({
    super.key,
    required this.rootLocationId,
    required this.parentId,
  });

  final int rootLocationId;
  final int parentId;

  @override
  State<EditableLocationCard> createState() => _EditableLocationCardState();
}

class _EditableLocationCardState extends State<EditableLocationCard> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => PartyStateDialog(
            onAccept: () {
              LocationService.createLocation(
                Location(
                  name: controller.text,
                  elementType: ElementType.card,
                  rootLocationId: widget.rootLocationId,
                  parentId: widget.parentId,
                ),
              ).then((_) =>
                  Provider.of<LocationProvider>(context, listen: false)
                      .loadRootLocation(reloadCurrent: true));
            },
            title: "Add location card",
            content: _createNewLocationDialogContent(),
          ),
        ),
        child: _buildCardName(),
      ),
    );
  }

  Widget _buildCardName() => const Padding(
        padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 5),
        child: Icon(Icons.add),
      );

  Widget _createNewLocationDialogContent() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Please provide a name for your new location card"),
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
