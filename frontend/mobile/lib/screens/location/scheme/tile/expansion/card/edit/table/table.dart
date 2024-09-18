import 'package:flutter/material.dart';
import 'package:party_radar/models/location.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/edit/table/dialogs/radio_edit_dialog.dart';
import 'package:party_radar/screens/location/scheme/tile/expansion/card/edit/table/widgets/editable_radio_widget.dart';
import 'package:party_radar/services/location_service.dart';
import 'package:provider/provider.dart';

class TableWidget extends StatefulWidget {
  const TableWidget({super.key, required this.location});

  final Location location;

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  // [column][row]
  List<List<EditableRadioWidget>> list = [];

  void initTable(List<Location> locationList) {
    if (locationList.isNotEmpty) {
      locationList
          .sort((a, b) => (a.columnIndex ?? 0).compareTo(b.columnIndex ?? 0));

      list = List.generate(
          (locationList.last.columnIndex ?? 0) + 1, (index) => []);

      for (int i = 0; i < locationList.length; i++) {
        list.elementAt(locationList[i].columnIndex ?? 0).add(
          EditableRadioWidget(
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
          EditableRadioWidget(
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
      EditableRadioWidget(
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
                  for (List<EditableRadioWidget> columnChildren in list) {
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
    builder: (context) => RadioEditDialog(
      location: location,
      onUpdate: () => setState(() {}),
    ),
  );

  void addColumn() {
    bool rowAdded = false;
    var currentColumn = list.length - 1;

    if (list.elementAt(currentColumn).length == 1) {
      addRow(currentColumn);
      rowAdded = true;
    }

    list.insert(list.length - 1, [
      EditableRadioWidget(
        locationName: "Add row",
        rowIndex: 0,
        columnIndex: currentColumn,
        onClick: () => addRow(currentColumn),
        isAdd: true,
      )
    ]);
    list.add([
      EditableRadioWidget(
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
        EditableRadioWidget(
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