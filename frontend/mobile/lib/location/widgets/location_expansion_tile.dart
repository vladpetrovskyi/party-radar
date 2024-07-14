import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/location_page.dart';
import 'package:party_radar/location/widgets/editable_location_list_tile.dart';
import 'package:party_radar/location/widgets/location_card.dart';

class LocationExpansionTile extends EditableLocationListTile {
  const LocationExpansionTile({
    super.key,
    required super.location,
    required super.title,
    super.isEditMode = false,
    super.textEditingController,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController newLocationNameFieldController =
        TextEditingController();

    return ExpansionTile(
      title: getTitle(),
      subtitle: getSubtitle(),
      trailing: getTrailing(),
      children: [
        FutureBuilder(
          future: LocationService.getLocationChildren(location.id,
              visibleOnly: true),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Could not build locations, an error occurred");
            }
            if (snapshot.hasData) {
              return _getGridView(
                  snapshot.data!, newLocationNameFieldController);
            }
            return const CircularProgressIndicator();
          },
        )
      ],
    );
  }

  Widget _getGridView(List<Location> locationChildren,
          TextEditingController newLocationNameFieldController) =>
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2.0,
          childAspectRatio: 1.5,
        ),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(10.0),
        itemCount: isEditMode
            ? (locationChildren.length + 1)
            : locationChildren.length,
        itemBuilder: (context, index) {
          if (isEditMode && index == locationChildren.length) {
            return EditableLocationCard(
                newLocationNameFieldController: newLocationNameFieldController);
          }

          if (locationChildren[index].deletedAt == null) {
            return LocationCard(
              location: locationChildren[index],
              isEditMode: isEditMode,
            );
          }
          return Container();
        },
      );

  @override
  Widget? getTrailing() => isEditMode
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [const Icon(Icons.arrow_drop_down), popupMenu],
        )
      : null;
}

class EditableLocationCard extends StatelessWidget {
  const EditableLocationCard(
      {super.key, required this.newLocationNameFieldController});

  final TextEditingController newLocationNameFieldController;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => PartyStateDialog(
            onAccept: () {},
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
              controller: newLocationNameFieldController,
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
