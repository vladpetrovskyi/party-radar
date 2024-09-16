import 'package:flutter/material.dart';
import 'package:party_radar/common/models.dart';
import 'package:party_radar/location/widgets/radio_list_tile.dart';

class DialogRadiosWidget extends StatelessWidget {
  const DialogRadiosWidget({
    super.key,
    required this.locations,
    required this.onChangeSelectedRadio,
    required this.selectedRadio,
  });

  final List<Location> locations;
  final Function(int?) onChangeSelectedRadio;
  final int? selectedRadio;

  @override
  Widget build(BuildContext context) {
    locations.sort((a, b) => (a.columnIndex ?? 0).compareTo(b.columnIndex ?? 0));

    List<List<RadioListTileWidget>> columnList =
        List.generate((locations.last.columnIndex ?? 0) + 1, (index) => []);
    for (int i = 0; i < locations.length; i++) {
      columnList.elementAt(locations[i].columnIndex ?? 0).add(
            RadioListTileWidget(
              locationId: locations[i].id!,
              locationName: locations[i].name,
              selectedValue: selectedRadio,
              onChanged: onChangeSelectedRadio,
              locationRowIndex: locations[i].rowIndex ?? 0,
            ),
          );
    }

    columnList.removeWhere((col) => col.isEmpty);

    List<Column> columns = [];

    for (List<RadioListTileWidget> columnChildren in columnList) {
      columnChildren
          .sort((a, b) => a.locationRowIndex.compareTo(b.locationRowIndex));
      columns.add(Column(children: [...columnChildren]));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [...columns],
    );
  }
}
