import 'package:flutter/material.dart';

class RadioListTileWidget extends StatelessWidget {
  const RadioListTileWidget({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.selectedValue,
    required this.locationRowIndex,
    this.onChanged,
  });

  final int locationId;
  final String locationName;
  final int? selectedValue;
  final Function(int? id)? onChanged;
  final int locationRowIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Radio(
          visualDensity: const VisualDensity(
            horizontal: VisualDensity.minimumDensity,
            vertical: VisualDensity.minimumDensity,
          ),
          value: locationId,
          groupValue: selectedValue,
          onChanged: onChanged,
          toggleable: true,
        ),
        Text(locationName),
      ],
    );
  }
}
