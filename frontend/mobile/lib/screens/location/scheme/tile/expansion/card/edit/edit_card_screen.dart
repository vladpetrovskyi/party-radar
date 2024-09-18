import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:party_radar/models/dialog_settings.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/edit/table/table.dart';
import 'package:party_radar/services/dialog_settings_service.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/location_closing_service.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class EditCardScreen extends StatefulWidget {
  const EditCardScreen({
    super.key,
    required this.location,
    required this.handle,
  });

  final Function(Location) handle;
  final Location location;

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> with ErrorSnackBar {
  late final Location _location;
  bool _isImageLoading = false;

  late final TextEditingController emojiController;
  late final TextEditingController titleController;
  late final TextEditingController dialogNameController;

  final FocusNode emojiFocusNode = FocusNode();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode dialogNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    emojiController = TextEditingController(text: widget.location.emoji);
    titleController = TextEditingController(text: widget.location.name);
    dialogNameController =
        TextEditingController(text: widget.location.dialogName);

    emojiFocusNode.addListener(() {
      if (!emojiFocusNode.hasFocus) {
        _updateEmoji();
      }
    });
    titleFocusNode.addListener(() {
      if (!titleFocusNode.hasFocus) {
        _updateTitle();
      }
    });
    dialogNameFocusNode.addListener(() {
      if (!dialogNameFocusNode.hasFocus) {
        _updateDialogName();
      }
    });
  }

  @override
  void dispose() {
    emojiController.dispose();
    titleController.dispose();
    dialogNameController.dispose();
    emojiFocusNode.dispose();
    titleFocusNode.dispose();
    dialogNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [deleteCardIcon],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            getLargeHeadline('Card settings'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [emojiEditField, titleEditField],
            ),
            cardEnabledSwitch,
            locationCloseableSwitch,
            dialogEnabledSwitch,
            if (_location.dialogId != null) ...cardDialogSettings,
          ],
        ),
      ),
    );
  }

  Widget getLargeHeadline(String label) => Text(
        label,
        style: Theme.of(context).textTheme.headlineLarge,
      );

  Widget get deleteCardIcon => IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => PartyStateDialog(
            title: 'Delete card',
            content: const Text('This action cannot be reverted!'),
            onAccept: () => _deleteLocation(),
          ),
        ),
        icon: const Icon(Icons.delete_outline),
      );

  Widget get emojiEditField => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: TextFormField(
            focusNode: emojiFocusNode,
            controller: emojiController,
            decoration: const InputDecoration(
              label: Text('Card emoji (top)'),
              border: OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onTapOutside: (_) => _updateEmoji(),
            onFieldSubmitted: (_) => _updateEmoji(),
          ),
        ),
      );

  Widget get titleEditField => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: TextFormField(
            focusNode: titleFocusNode,
            controller: titleController,
            decoration: const InputDecoration(
              label: Text('Card title (bottom)'),
              border: OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (val) =>
                val == null || val.isEmpty ? "Title can't be empty" : null,
            onFieldSubmitted: (_) => _updateTitle(),
            onTapOutside: (_) => _updateTitle(),
          ),
        ),
      );

  Widget get cardEnabledSwitch => SwitchListTile(
        title: const Text("Location enabled"),
        subtitle: const Text("Card is visible in the list"),
        value: _location.enabled,
        onChanged: (newVal) {
          _location.enabled = newVal;
          _updateLocation();
        },
      );

  Widget get locationCloseableSwitch => SwitchListTile(
        title: const Text("Is closeable"),
        subtitle: const Text(
            "Card can be marked as closed on long tap (with a timer and red overlay)"),
        value: _location.isCloseable,
        onChanged: (closeable) => _setCloseable(closeable),
      );

  Widget get dialogEnabledSwitch => SwitchListTile(
        title: const Text("Dialog enabled"),
        subtitle: const Text("Selection dialog opens on click"),
        value: _location.dialogId != null,
        onChanged: (newVal) => _setDialogEnabled(newVal),
      );

  List<Widget> get cardDialogSettings => [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: getLargeHeadline('Card dialog settings'),
        ),
        const Divider(),
        _dialogNameEditField,
        ..._dialogImageSettings,
        _schemaTitle,
        _schemaEditCard,
        _selectableCapacitySwitch,
        const SizedBox(height: 4),
      ];

  Widget get _dialogNameEditField => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: TextFormField(
          focusNode: dialogNameFocusNode,
          controller: dialogNameController,
          decoration: const InputDecoration(
            label: Text('Dialog name'),
            border: OutlineInputBorder(),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTapOutside: (_) => _updateDialogName(),
          onFieldSubmitted: (_) => _updateDialogName(),
        ),
      );

  List<Widget> get _dialogImageSettings => [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Dialog image',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        _location.imageId != null
            ? FutureBuilder(
                future:
                    ImageService.get(_location.imageId, showErrorImage: false),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return getDialogImageCard(snapshot.data!);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              )
            : _addDialogImageButton,
      ];

  Widget get _addDialogImageButton => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FilledButton(
              onPressed: () => _addDialogImage(),
              child: const Text("Add dialog image")),
        ),
      );

  Widget getDialogImageCard(Image image) => Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          children: [
            _isImageLoading
                ? const Center(child: CircularProgressIndicator())
                : image,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                      onPressed: () => _updateDialogImage(),
                      child: const Text("Update image")),
                  FilledButton.tonal(
                    onPressed: () => _deleteDialogImage(),
                    child: const Text("Delete image"),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Widget get _schemaTitle => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall,
            children: const <TextSpan>[
              TextSpan(text: "Scheme"),
              TextSpan(
                text: " (mandatory)",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18),
              ),
            ],
          ),
        ),
      );

  Widget get _schemaEditCard => FutureBuilder(
        future: LocationService.getLocationChildren(_location.id),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Container();
          }
          if (snapshot.hasData) {
            return Card(child: TableWidget(location: _location));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );

  Widget get _selectableCapacitySwitch => SwitchListTile(
        title: const Text("Selectable capacity"),
        subtitle: const Text("Capacity selection toggle is visible"),
        value: _location.isCapacitySelectable ?? false,
        onChanged: (newVal) => _setIsCapacitySelectable(newVal),
      );

  _updateLocation() =>
      LocationService.updateLocation(_location).then((updated) {
        if (updated == null) {
          showErrorSnackBar("Error occurred, please try again", context);
          return;
        }
        // updated doesn't contain all fields that _location has,
        // for example dialog settings, onClickAction, ...
        widget.handle(_location);
        setState(() {});
      });

  _deleteLocation() =>
      LocationService.deleteLocation(_location.id).then((deleted) {
        Navigator.of(context).pop();
        if (!deleted) {
          showErrorSnackBar("Error occurred, please try again", context);
          return;
        }
        Navigator.of(context).pop();
        Provider.of<LocationProvider>(context, listen: false)
            .loadRootLocation(reloadCurrent: true);
      });

  _updateDialogName() {
    if (dialogNameController.text != _location.dialogName) {
      _location.dialogName = dialogNameController.text;
      DialogSettingsService().update(_dialogSettings).then(
            (updated) => updated
                ? setState(() {})
                : showErrorSnackBar(
                    "Error occurred, please try again", context),
          );
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  _updateEmoji() {
    if (widget.location.emoji != emojiController.text) {
      _location.emoji =
          emojiController.text.isEmpty ? null : emojiController.text;
      _updateLocation();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  DialogSettings get _dialogSettings => DialogSettings(
        id: _location.dialogId,
        locationId: _location.id!,
        name: _location.dialogName ?? '',
        isCapacitySelectable: _location.isCapacitySelectable ?? false,
      );

  _updateTitle() {
    if (widget.location.name != titleController.text) {
      _location.name = titleController.text;
      _updateLocation();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  _setCloseable(bool closeable) {
    if (closeable) {
      LocationClosingService().create(_location.id!).then((created) => created
          ? setState(() => _location.isCloseable = true)
          : showErrorSnackBar("Error occurred, please try again", context));
    } else {
      LocationClosingService().delete(_location.id!).then((deleted) => deleted
          ? setState(() => _location.isCloseable = false)
          : showErrorSnackBar("Error occurred, please try again", context));
    }
  }

  _setDialogEnabled(bool enabled) {
    if (enabled) {
      DialogSettingsService()
          .create(DialogSettings(locationId: _location.id!))
          .then((id) {
        _location.onClickAction = OnClickAction.openDialog;
        LocationService.updateLocation(_location);
        setState(() => _location.dialogId = id);
      });
    } else {
      DialogSettingsService().delete(_location.dialogId!).then((deleted) {
        if (deleted) {
          _location.onClickAction = OnClickAction.select;
          _location.dialogName = null;
          _location.isCapacitySelectable = null;
          _location.dialogId = null;
          LocationService.updateLocation(_location);
          setState(() {});
        }
      });
    }
  }

  _addDialogImage() async {
    final ImagePicker picker = ImagePicker();
    var imageFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() => _isImageLoading = true);
    var imageId = await ImageService.addForDialogSettings(
        File(imageFile!.path), _location.dialogId);

    if (!mounted) return;

    if (imageId == null) {
      showErrorSnackBar("Could not add image, please try again", context);
      return;
    }

    setState(() {
      _location.imageId = imageId;
      _isImageLoading = false;
    });
  }

  _updateDialogImage() async {
    final ImagePicker picker = ImagePicker();
    var imageFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() => _isImageLoading = true);
    var updated =
        await ImageService.update(_location.imageId!, File(imageFile!.path));

    if (!mounted) return;

    if (!updated) {
      showErrorSnackBar("Could not update image, please try again", context);
    }

    setState(() {
      _isImageLoading = false;
    });
  }

  _deleteDialogImage() =>
      ImageService.delete(_location.imageId!).then((deleted) => deleted
          ? setState(() => _location.imageId = null)
          : showErrorSnackBar("Error occurred, please try again", context));

  _setIsCapacitySelectable(bool newVal) {
    _location.isCapacitySelectable = newVal;
    DialogSettingsService().update(_dialogSettings).then((updated) => updated
        ? setState(() {})
        : showErrorSnackBar("Error occurred, please try again", context));
  }
}
