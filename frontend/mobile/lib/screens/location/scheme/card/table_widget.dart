import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class TableWidget extends StatefulWidget {
  const TableWidget({super.key, required this.location});

  final Location location;

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  // [column][row]
  List<List<EditableRadioTableWidget>> list = [];

  void initTable(List<Location> locationList) {
    if (locationList.isNotEmpty) {
      locationList
          .sort((a, b) => (a.columnIndex ?? 0).compareTo(b.columnIndex ?? 0));

      list = List.generate(
          (locationList.last.columnIndex ?? 0) + 1, (index) => []);

      for (int i = 0; i < locationList.length; i++) {
        list.elementAt(locationList[i].columnIndex ?? 0).add(
              EditableRadioTableWidget(
                locationId: locationList[i].id,
                locationName: locationList[i].name,
                rowIndex: locationList[i].rowIndex ?? 0,
                columnIndex: locationList[i].columnIndex ?? 0,
                onClick: () => _showLocationDialog(locationList[i]),
              ),
            );
      }

      for (int i = 0; i < list.length; i++) {
        var columnChildren = list.elementAt(i);

        if (columnChildren.isEmpty) continue;

        columnChildren.sort((a, b) => a.rowIndex.compareTo(b.rowIndex));

        columnChildren.add(
          EditableRadioTableWidget(
            locationName: "Add row",
            rowIndex: columnChildren.lastOrNull != null
                ? columnChildren.last.rowIndex + 1
                : 0,
            onClick: () => addRow(i),
            menu: getPopupMenu(i),
            columnIndex: i,
            isAdd: true,
          ),
        );
      }
    }

    list.add([
      EditableRadioTableWidget(
        locationName: "Add column",
        rowIndex: 0,
        columnIndex: list.length,
        onClick: () => addColumn(),
        isAdd: true,
      )
    ]);
  }

  PopupMenuButton getPopupMenu(int colIndex) => PopupMenuButton(
        enabled: true,
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: const Text('Add row'),
            onTap: () => addRow(colIndex),
          ),
          PopupMenuItem(
            child: const Text('Remove column'),
            onTap: () => removeColumn(colIndex),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: FutureBuilder(
              future: LocationService.getLocationChildren(widget.location.id),
              builder: (context, snapshot) {
                list = [];
                if (snapshot.hasError) {
                  return Container();
                }
                if (snapshot.hasData) {
                  initTable(snapshot.data!);

                  List<Column> columns = [];
                  for (List<EditableRadioTableWidget> columnChildren in list) {
                    columns.add(Column(children: [...columnChildren]));
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [...columns],
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(Location location) => showDialog<void>(
      context: context,
      builder: (context) => EditCardRadioDialog(
            location: location,
            onUpdate: () => setState(() {}),
          ));

  void addColumn() {
    bool rowAdded = false;
    var currentColumn = list.length - 1;

    if (list.elementAt(currentColumn).length == 1) {
      addRow(currentColumn);
      rowAdded = true;
    }

    list.insert(list.length - 1, [
      EditableRadioTableWidget(
        locationName: "Add row",
        rowIndex: 0,
        columnIndex: currentColumn,
        onClick: () => addRow(currentColumn),
        isAdd: true,
      )
    ]);
    list.add([
      EditableRadioTableWidget(
        locationName: "Add column",
        rowIndex: 0,
        columnIndex: list.length,
        onClick: () => addColumn(),
        isAdd: true,
      )
    ]);

    if (!rowAdded) setState(() {});
  }

  void addRow(int i) {
    var rootLocationId =
        Provider.of<LocationProvider>(context, listen: false).rootLocation?.id;
    var newLocation = Location(
        name: '',
        onClickAction: OnClickAction.select,
        columnIndex: i,
        parentId: widget.location.id,
        rootLocationId: rootLocationId,
        rowIndex: list.elementAt(i).last.rowIndex,
        enabled: true);
    LocationService.createLocation(newLocation)
        .then((createdLocation) => createdLocation != null
            ? setState(() {
                newLocation.id = createdLocation.id;
                list.elementAt(i).insert(
                      list.elementAt(i).length - 1,
                      EditableRadioTableWidget(
                        locationId: newLocation.id,
                        locationName: '',
                        rowIndex: list.elementAt(i).length,
                        columnIndex: i,
                        onClick: () => _showLocationDialog(newLocation),
                      ),
                    );
              })
            : null);
  }

  void removeColumn(int i) {
    List<Future<bool>> futureList = [];
    list.elementAt(i).forEach((e) => e.locationId != null
        ? futureList.add(LocationService.deleteLocation(e.locationId))
        : null);

    Future.wait(futureList).then((_) => setState(() {}));
  }
}

class EditableRadioTableWidget extends StatelessWidget {
  const EditableRadioTableWidget({
    super.key,
    this.locationId,
    required this.locationName,
    required this.rowIndex,
    required this.columnIndex,
    required this.onClick,
    this.menu,
    this.isAdd = false,
  });

  final int? locationId;
  final String locationName;
  final int rowIndex;
  final int columnIndex;
  final Function() onClick;
  final Widget? menu;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: EdgeInsets.only(left: 10, right: isAdd ? 10 : 0),
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow()]),
      child: !isAdd
          ? Row(
              children: [
                Text(locationName),
                IconButton(onPressed: onClick, icon: const Icon(Icons.edit))
              ],
            )
          : menu ?? IconButton(onPressed: onClick, icon: const Icon(Icons.add)),
    );
  }
}

class EditCardRadioDialog extends StatefulWidget {
  const EditCardRadioDialog(
      {super.key, required this.location, required this.onUpdate});

  final VoidCallback onUpdate;
  final Location location;

  @override
  State<EditCardRadioDialog> createState() => _EditCardRadioDialogState();
}

class _EditCardRadioDialogState extends State<EditCardRadioDialog>
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
          onPressed: () {
            LocationService.deleteLocation(widget.location.id!).then((deleted) {
              if (!deleted) {
                showErrorSnackBar("Error occurred, please try again", context);
                return;
              }
              widget.onUpdate();
            });
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.delete_outline),
        ),
        ElevatedButton(
          onPressed: () {
            widget.location.name = _nameController.text;
            LocationService.updateLocation(widget.location).then((updated) {
              if (updated == null) {
                showErrorSnackBar("Error occurred, please try again", context);
                return;
              }
              widget.onUpdate();
            });
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}
