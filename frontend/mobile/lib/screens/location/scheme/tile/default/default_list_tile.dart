import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/dialogs/share_location_dialog_builder.dart';
import 'package:party_radar/screens/location/scheme/tile/widgets/user_dots_widget.dart';
import 'package:party_radar/services/location_service.dart';

class DefaultListTile extends StatefulWidget {
  const DefaultListTile({
    super.key,
    required this.location,
    required this.locationProvider,
    this.isEditMode = false,
    required this.title,
  });

  final Widget title;
  final bool isEditMode;
  final Location location;
  final LocationProvider locationProvider;

  @override
  State<DefaultListTile> createState() => _DefaultListTileState();
}

class _DefaultListTileState extends State<DefaultListTile>
    with ShareLocationDialogBuilder {
  late final Location _location;
  late final TextEditingController emojiController;
  late final TextEditingController titleController;
  final FocusNode emojiFocusNode = FocusNode();
  final FocusNode titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    emojiController = TextEditingController(text: widget.location.emoji);
    titleController = TextEditingController(text: widget.location.name);

    emojiFocusNode.addListener(() {
      if (!emojiFocusNode.hasFocus) {
        _updateEmoji(emojiController.text);
      }
    });
    titleFocusNode.addListener(() {
      if (!titleFocusNode.hasFocus) {
        _updateTitle(titleController.text);
      }
    });
  }

  @override
  void dispose() {
    emojiController.dispose();
    titleController.dispose();
    emojiFocusNode.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: widget.isEditMode ? true : widget.location.enabled,
      onTap: getOnTapFunction(context),
      title: getTitle(),
      subtitle: getSubtitle(),
      trailing: getTrailing(),
    );
  }

  Function() getOnTapFunction(BuildContext context) => () => widget.isEditMode
      ? null
      : buildShareLocationDialog(context, widget.location.id);

  Widget get inputField {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: TextFormField(
              focusNode: emojiFocusNode,
              controller: emojiController,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onFieldSubmitted: (val) => _updateEmoji(val),
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
              focusNode: titleFocusNode,
              controller: titleController,
              onTapOutside: (_) =>  FocusManager.instance.primaryFocus?.unfocus(),
              onFieldSubmitted: (val) => _updateTitle(val),
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

  UserDotsWidget? getSubtitle() => widget.location.enabled &&
          !widget.isEditMode &&
          widget.location.id != null
      ? UserDotsWidget(locationId: widget.location.id!)
      : null;

  Widget getTitle() => widget.isEditMode ? inputField : widget.title;

  Widget? getTrailing() => widget.isEditMode ? popupMenu : null;

  PopupMenuButton get popupMenu => PopupMenuButton(
        enabled: true,
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: Text('Set ${_location.enabled ? 'disabled' : 'enabled'}'),
            onTap: () {
              _location.enabled = !_location.enabled;
              LocationService.updateLocation(_location);
            },
          ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () async {
              if (await LocationService.deleteLocation(_location.id)) {
                widget.locationProvider.loadRootLocation(reloadCurrent: true);
              }
            },
          ),
        ],
      );

  _updateEmoji(String text) {
    if (_location.emoji != text) {
      _location.emoji = text;
      LocationService.updateLocation(_location);
    }
  }

  _updateTitle(String text) {
    if (_location.name != text) {
      _location.name = text;
      LocationService.updateLocation(_location);
    }
  }
}
