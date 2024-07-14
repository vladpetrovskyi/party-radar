import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/widgets/user_dots_widget.dart';

abstract class EditableLocationListTile extends StatelessWidget {
  const EditableLocationListTile({
    super.key,
    required this.location,
    this.isEditMode = false,
    this.textEditingController,
    required this.title,
  });

  final Location location;
  final bool isEditMode;
  final TextEditingController? textEditingController;
  final Widget title;

  TextField get inputField => TextField(
        controller: textEditingController,
        onChanged: (val) => location.name = val,
        style: const TextStyle(
          fontSize: 28,
        ),
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color.fromRGBO(119, 136, 153, 0.05),
          border: UnderlineInputBorder(),
          isCollapsed: true,
        ),
      );

  UserDotsWidget? getSubtitle() =>
      location.enabled && !isEditMode && location.id != null
          ? UserDotsWidget(locationId: location.id!)
          : null;

  Widget getTitle() => isEditMode ? inputField : title;

  Widget? getTrailing() => isEditMode ? popupMenu : null;

  PopupMenuButton get popupMenu => PopupMenuButton(
        enabled: true,
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: Text('Set ${location.enabled ? 'disabled' : 'enabled'}'),
            onTap: () => location.enabled = !location.enabled,
          ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () {
              // TODO: send delete and reload view
            },
          ),
        ],
      );
}
