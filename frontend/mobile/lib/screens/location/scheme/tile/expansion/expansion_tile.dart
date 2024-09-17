import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/dialogs/share_location_dialog_builder.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/card.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/editable_card.dart';
import 'package:party_radar/screens/location/scheme/tile/widgets/user_dots_widget.dart';
import 'package:party_radar/services/location_service.dart';

class LocationExpansionTile extends StatefulWidget {
  const LocationExpansionTile({
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
  State<LocationExpansionTile> createState() => _LocationExpansionTileState();
}

class _LocationExpansionTileState extends State<LocationExpansionTile>
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
    return ExpansionTile(
      onExpansionChanged: (expanded) => expanded
          ? widget.locationProvider.lastOpenedExpansions.add(_location.id)
          : widget.locationProvider.lastOpenedExpansions.remove(_location.id),
      initiallyExpanded:
          widget.locationProvider.lastOpenedExpansions.contains(_location.id),
      title: getTitle(),
      subtitle: getSubtitle(),
      trailing: getTrailing(),
      children: [
        FutureBuilder(
          future: LocationService.getLocationChildren(_location.id,
              visibleOnly: true),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Could not build locations, an error occurred");
            }
            if (snapshot.hasData) {
              return _getGridView(snapshot.data!);
            }
            return const CircularProgressIndicator();
          },
        )
      ],
    );
  }

  Widget _getGridView(List<Location> locationChildren) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2.0,
          childAspectRatio: 1.5,
        ),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(10.0),
        itemCount: widget.isEditMode
            ? (locationChildren.length + 1)
            : locationChildren.length,
        itemBuilder: (context, index) {
          if (widget.isEditMode && index == locationChildren.length) {
            return EditableLocationCard(
                rootLocationId: _location.rootLocationId!,
                parentId: _location.id!);
          }

          var locationChild = locationChildren[index];

          if (locationChild.deletedAt == null &&
              ((!widget.isEditMode && locationChild.enabled) || widget.isEditMode)) {
            return LocationCard(
              location: locationChildren[index],
              isEditMode: widget.isEditMode,
            );
          }
          return null;
        },
      );

  Widget? getTrailing() => widget.isEditMode
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [const Icon(Icons.arrow_drop_down), popupMenu],
        )
      : null;

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
              onTapOutside: (_) => _updateEmoji(emojiController.text),
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
              onTapOutside: (_) => _updateTitle(titleController.text),
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
    FocusManager.instance.primaryFocus?.unfocus();
  }

  _updateTitle(String text) {
    if (_location.name != text) {
      _location.name = text;
      LocationService.updateLocation(_location);
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
