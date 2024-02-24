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
    locations.sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

    List<List<RadioListTileWidget>> columnList =
        List.generate(locations.last.columnIndex + 1, (index) => []);
    for (int i = 0; i < locations.length; i++) {
      columnList.elementAt(locations[i].columnIndex).add(
            RadioListTileWidget(
              locationId: locations[i].id,
              locationName: locations[i].name,
              selectedValue: selectedRadio,
              onChanged: onChangeSelectedRadio,
              locationRowIndex: locations[i].rowIndex,
            ),
          );
    }

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
