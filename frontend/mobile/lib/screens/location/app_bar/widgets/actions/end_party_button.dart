import 'package:flutter/material.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';

class EndPartyButton extends StatelessWidget with ErrorSnackBar {
  const EndPartyButton({
    super.key,
    required this.userProvider,
    required this.locationProvider,
  });

  final UserProvider userProvider;
  final LocationProvider locationProvider;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => PartyStateDialog(
            onAccept: () => _leaveTheLocation(context),
            title: 'Leaving the club?',
            content: const Text(
                'An update with the time you left will be posted to the feed'),
          ),
        );
      },
      icon: const Icon(Icons.stop_circle_outlined),
    );
  }

  void _leaveTheLocation(BuildContext context) async {
    UserService.deleteUserLocation().then(
          (userLocationDeleted) {
        if (!userLocationDeleted) {
          showErrorSnackBar(
              'Could not check you out from the current location', context);
          return;
        }

        var userRootLocationId = userProvider.user?.rootLocationId;
        userProvider.updateUser();

        locationProvider.loadRootLocation(locationId: userRootLocationId);
        locationProvider.loadCurrentLocationTree();
      },
    );
  }
}