import 'package:flutter/material.dart';

class RadioListTileWidget extends StatelessWidget {
  const RadioListTileWidget({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.selectedValue,
    this.onChanged,
  });

  final int locationId;
  final String locationName;
  final int? selectedValue;
  final Function(int? id)? onChanged;

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
        ),
        Text(locationName),
      ],
    );
  }
}
