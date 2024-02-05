import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/common/flavors/flavor_config.dart';
import 'package:party_radar/location/dialogs/share_location_dialog.dart';

mixin ShareLocationDialogBuilder {
  @protected
  Function() get onLocationChanged;

  Future<void>? buildShareLocationDialog(BuildContext context, int locationId) {
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
      builder: (BuildContext context) {
        return ShareLocationDialog(
          onCurrentLocationChanged: onLocationChanged,
          locationId: locationId,
        );
      },
    );
  }

  bool _isRegistrationFinished() {
    return (FirebaseAuth.instance.currentUser!.emailVerified ||
            FlavorConfig.instance.flavor != Flavor.prod) &&
        FirebaseAuth.instance.currentUser!.displayName != null;
  }
}
