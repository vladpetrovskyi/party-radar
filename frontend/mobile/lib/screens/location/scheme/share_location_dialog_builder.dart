import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/screens/location/scheme/share_location_dialog.dart';

mixin ShareLocationDialogBuilder {
  Future<void>? buildShareLocationDialog(BuildContext context, int? locationId) {
    if (locationId == null) return null;

    if (!_isRegistrationFinished()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify your email first!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    return showDialog<void>(
      context: context,
      builder: (context) => ShareLocationDialog(locationId: locationId),
    );
  }

  bool _isRegistrationFinished() {
    return (FirebaseAuth.instance.currentUser!.emailVerified ||
            FlavorConfig.instance.flavor != Flavor.prod) &&
        FirebaseAuth.instance.currentUser!.displayName != null;
  }
}
