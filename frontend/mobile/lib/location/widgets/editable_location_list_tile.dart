import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

import '../../common/services/location_service.dart';

abstract class EditableLocationListTile extends StatelessWidget {
  const EditableLocationListTile({
    super.key,
    required this.title,
    required this.location,
    required this.locationProvider,
    this.isEditMode = false,
  });

  final Widget title;
  final bool isEditMode;
  final Location location;
  final LocationProvider locationProvider;

  Widget get inputField {
    final TextEditingController controller =
        TextEditingController(text: location.emoji);
    final TextEditingController titleController =
        TextEditingController(text: location.name);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: TextFormField(
              controller: controller,
              onTapOutside: (_) {
                if (location.emoji != controller.text) {
                  location.emoji = controller.text;
                  LocationService.updateLocation(location);
                }
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onFieldSubmitted: (val) {
                if (location.emoji != val) {
                  location.emoji = controller.text;
                  LocationService.updateLocation(location);
                }
              },
              style: const TextStyle(
                fontSize: 28,
              ),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(119, 136, 153, 0.05),
                border: UnderlineInputBorder(),
                isCollapsed: true,
                hintText: "🙂",
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: TextFormField(
              controller: titleController,
              onTapOutside: (_) {
                if (location.name != titleController.text) {
                  location.name = titleController.text;
                  LocationService.updateLocation(location);
                }
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onFieldSubmitted: (val) {
                if (location.name != val) {
                  location.name = titleController.text;
                  LocationService.updateLocation(location);
                }
              },
              style: const TextStyle(
                fontSize: 28,
              ),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(119, 136, 153, 0.05),
                border: UnderlineInputBorder(),
                isCollapsed: true,
                hintText: "Title",
              ),
            ),
          ),
        ),
      ],
    );
  }

  UserDotsWidget? getSubtitle() =>
      location.enabled && !isEditMode && location.id != null
          ? UserDotsWidget(locationId: location.id!)
          : null;

  Widget getTitle() => isEditMode ? inputField : title;

  Widget? getTrailing() => isEditMode ? popupMenu : null;

  PopupMenuButton get popupMenu => PopupMenuButton(
        enabled: true,
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: Text('Set ${location.enabled ? 'disabled' : 'enabled'}'),
            onTap: () {
              location.enabled = !location.enabled;
              LocationService.updateLocation(location);
            },
          ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () async {
              if (await LocationService.deleteLocation(location.id)) {
                locationProvider.loadRootLocation(reloadCurrent: true);
              }
            },
          ),
        ],
      );
}
