import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/flavors/flavor_config.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/scheme/tile/dialogs/share_location_dialog.dart';
import 'package:provider/provider.dart';

mixin ShareLocationDialogBuilder {
  Future<void>? buildShareLocationDialog(
      BuildContext context, int? locationId) {
    if (locationId == null) return null;

    if (!_isActive(context)) {
      _showErrorSnackBar(
          'Please check in first by pressing play button', context);
      return null;
    }

    if (!_isRegistrationFinished()) {
      _showErrorSnackBar('Please verify your email first!', context);
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

  bool _isActive(BuildContext context) {
    var rootLocation =
        Provider.of<LocationProvider>(context, listen: false).rootLocation;
    var userRootLocationId =
        Provider.of<UserProvider>(context, listen: false).user?.rootLocationId;
    return userRootLocationId != null && userRootLocationId == rootLocation?.id;
  }

  void _showErrorSnackBar(String message, BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
}
