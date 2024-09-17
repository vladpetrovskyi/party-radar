import 'package:flutter/material.dart';

class EditableRadioWidget extends StatelessWidget {
  const EditableRadioWidget({
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
