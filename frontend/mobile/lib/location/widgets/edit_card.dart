import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:party_radar/common/error_snack_bar.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/common/providers.dart';
import 'package:party_radar/common/services/dialog_settings_service.dart';
import 'package:party_radar/common/services/location_closing_service.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/location/widgets/table_widget.dart';
import 'package:provider/provider.dart';

import '../../common/services/image_service.dart';

class EditCardPage extends StatefulWidget {
  const EditCardPage({super.key, required this.location, required this.handle});

  final Function(Location) handle;
  final Location location;

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> with ErrorSnackBar {
  late final Location _location;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emojiController =
    TextEditingController(text: _location.emoji);
    final TextEditingController titleController =
    TextEditingController(text: _location.name);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: _showDeleteCardDialog,
              icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            // CARD SETTINGS HEADLINE
            Text(
              'Card settings',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineLarge,
            ),
            const Divider(),

            // CARD NAME (title + subtitle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4),
                    child: TextFormField(
                      controller: emojiController,
                      decoration: const InputDecoration(
                        label: Text('Card emoji (top)'),
                        border: OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onTapOutside: (_) {
                        if (widget.location.emoji != emojiController.text) {
                          _location.emoji = emojiController.text.isEmpty
                              ? null
                              : emojiController.text;
                          _updateLocation();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onFieldSubmitted: (val) {
                        if (widget.location.emoji != val) {
                          _location.emoji = val.isEmpty ? null : val;
                          _updateLocation();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4),
                    child: TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        label: Text('Card title (bottom)'),
                        border: OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (val) =>
                      val == null || val.isEmpty
                          ? "Title can't be empty"
                          : null,
                      onFieldSubmitted: (val) {
                        if (widget.location.name != val) {
                          _location.name = val;
                          _updateLocation();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onTapOutside: (_) {
                        if (widget.location.name != titleController.text) {
                          _location.name = titleController.text;
                          _updateLocation();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                ),
              ],
            ),

            // CARD ENABLED SWITCH
            SwitchListTile(
              title: const Text("Location enabled"),
              subtitle: const Text("Card is visible in the list"),
              value: _location.enabled,
              onChanged: (newVal) {
                _location.enabled = newVal;
                _updateLocation();
              },
            ),

            // LOCATION CLOSEABLE SWITCH
            SwitchListTile(
              title: const Text("Is closeable"),
              subtitle: const Text(
                  "Card can be marked as closed on long tap (with a timer and red overlay)"),
              value: _location.isCloseable,
              onChanged: (closeable) {
                if (closeable) {
                  LocationClosingService().create(_location.id!).then(
                          (created) =>
                      created
                          ? setState(() => _location.isCloseable = true)
                          : showErrorSnackBar(
                          "Error occurred, please try again", context));
                } else {
                  LocationClosingService().delete(_location.id!).then(
                          (deleted) =>
                      deleted
                          ? setState(() => _location.isCloseable = false)
                          : showErrorSnackBar(
                          "Error occurred, please try again", context));
                }
              },
            ),

            SwitchListTile(
              title: const Text("Dialog enabled"),
              subtitle: const Text("Selection dialog opens on click"),
              value: _location.dialogId != null,
              onChanged: (newVal) {
                if (newVal) {
                  DialogSettingsService()
                      .create(DialogSettings(locationId: _location.id!))
                      .then((id) {
                    _location.onClickAction = OnClickAction.openDialog;
                    LocationService.updateLocation(_location);
                    setState(() => _location.dialogId = id);
                  });
                } else {
                  DialogSettingsService()
                      .delete(_location.dialogId!)
                      .then((deleted) {
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
              },
            ),

            // CARD DIALOG SETTINGS
            if (_location.dialogId != null) ..._cardDialogSettings,
          ],
        ),
      ),
    );
  }

  List<Widget> get _cardDialogSettings {
    final TextEditingController dialogNameController = TextEditingController(
        text: _location.dialogName);
    return [
      // CARD DIALOG SETTINGS HEADLINE
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Card dialog settings',
          style: Theme
              .of(context)
              .textTheme
              .headlineLarge,
        ),
      ),
      const Divider(),

      // 2. DIALOG NAME
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: TextFormField(
          controller: dialogNameController,
          decoration: const InputDecoration(
            label: Text('Dialog name'),
            border: OutlineInputBorder(),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTapOutside: (_) {
            if (dialogNameController.text != _location.dialogName) {
              _location.dialogName = dialogNameController.text;
              DialogSettingsService().update(dialogSettings).then(
                    (updated) =>
                updated
                    ? setState(() {})
                    : showErrorSnackBar(
                    "Error occurred, please try again", context),
              );
            }
            FocusManager.instance.primaryFocus?.unfocus();
          },
          onFieldSubmitted: (val) {
            if (val != _location.dialogName) {
              _location.dialogName = val;
              DialogSettingsService().update(dialogSettings).then(
                    (updated) =>
                updated
                    ? setState(() {})
                    : showErrorSnackBar(
                    "Error occurred, please try again", context),
              );
            }
          },
        ),
      ),

      // 3.1. IMAGE NAME
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Dialog image',
            style: Theme
                .of(context)
                .textTheme
                .headlineSmall,
          ),
        ),
      ),

      // 3.2. IMAGE ACTION BUTTON(-S)
      _location.imageId != null
          ? FutureBuilder(
        future: ImageService.get(_location.imageId,
            showErrorImage: false),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Card(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Column(
                children: [
                  _isImageLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : snapshot.data!,
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton(
                            onPressed: () async {
                              final ImagePicker picker =
                              ImagePicker();
                              var imageFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              setState(() => _isImageLoading = true);
                              var updated = await ImageService.update(
                                  _location.imageId!,
                                  File(imageFile!.path));

                              if (!mounted) return;
                              if (!updated) {
                                showErrorSnackBar(
                                    "Could not add image, please try again",
                                    this.context);
                              }

                              setState(() {
                                _isImageLoading = false;
                              });
                            },
                            child: const Text("Update image")),
                        FilledButton.tonal(
                          onPressed: () {
                            ImageService.delete(_location.imageId!)
                                .then((deleted) =>
                            deleted
                                ? setState(() =>
                            _location.imageId = null)
                                : showErrorSnackBar(
                                "Error occurred, please try again",
                                context));
                          },
                          child: const Text("Delete image"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      )
          : Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FilledButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                var imageFile = await picker.pickImage(
                    source: ImageSource.gallery);

                setState(() => _isImageLoading = true);
                var imageId = await ImageService.addForDialogSettings(
                    File(imageFile!.path), _location.dialogId);

                if (!mounted) return;

                if (imageId == null) {
                  showErrorSnackBar(
                      "Could not add image, please try again",
                      context);
                  return;
                }

                setState(() {
                  _location.imageId = imageId;
                  _isImageLoading = false;
                });
              },
              child: const Text("Add dialog image")),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: RichText(
          text: TextSpan(
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineSmall,
              children: const <TextSpan>[
                TextSpan(text: "Schema"),
                TextSpan(
                    text: " (mandatory)",
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ]),
        ),
      ),

      // 4. STALLS REPRESENTATION SETTINGS
      FutureBuilder(
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
      ),

      // 5. SELECTABLE CAPACITY SWITCH
      SwitchListTile(
        title: const Text("Selectable capacity"),
        subtitle: const Text("Capacity selection toggle is visible"),
        value: _location.isCapacitySelectable ?? false,
        onChanged: (newVal) {
          _location.isCapacitySelectable = newVal;
          DialogSettingsService().update(dialogSettings).then((updated) =>
          updated
              ? setState(() {})
              : showErrorSnackBar(
              "Error occurred, please try again", context));
        },
      ),
      const SizedBox(height: 4),
    ];
  }

  void _showDeleteCardDialog() =>
      showDialog(
        context: context,
        builder: (context) => DeleteCardDialog(location: _location),
      );

  void _updateLocation() =>
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

  DialogSettings get dialogSettings =>
      DialogSettings(
        id: _location.dialogId,
        locationId: _location.id!,
        name: _location.dialogName ?? '',
        isCapacitySelectable: _location.isCapacitySelectable ?? false,
      );
}

class DeleteCardDialog extends StatelessWidget with ErrorSnackBar {
  const DeleteCardDialog({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete card'),
      content: const Text('This action cannot be reverted!'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        ElevatedButton(
          onPressed: () {
            LocationService.deleteLocation(location.id).then((deleted) {
              Navigator.of(context).pop();
              if (!deleted) {
                showErrorSnackBar("Error occurred, please try again", context);
                return;
              }
              Navigator.of(context).pop();
              Provider.of<LocationProvider>(context, listen: false)
                  .loadRootLocation(reloadCurrent: true);
            });
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}
