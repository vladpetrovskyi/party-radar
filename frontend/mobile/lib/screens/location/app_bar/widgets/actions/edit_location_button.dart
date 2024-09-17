import 'package:flutter/material.dart';
import 'package:party_radar/providers/location_provider.dart';

class EditLocationButton extends StatelessWidget {
  const EditLocationButton({super.key, required this.locationProvider});

  final LocationProvider locationProvider;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => locationProvider.setEditMode(null),
      icon: locationProvider.editMode
          ? const Icon(Icons.check)
          : const Icon(Icons.edit_outlined),
    );
  }
}
