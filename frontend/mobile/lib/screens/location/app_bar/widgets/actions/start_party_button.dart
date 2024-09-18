import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/dialogs/party_state_dialog.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';

class StartPartyButton extends StatelessWidget with ErrorSnackBar {
  const StartPartyButton({
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
          if (userProvider.user?.rootLocationId != null &&
              userProvider.user?.rootLocationId !=
                  locationProvider.rootLocation?.id) {
            showErrorSnackBar(
                "You are currently checked in at another location. Please check out first.",
                context);
            return;
          }
          showDialog(
            context: context,
            builder: (context) => PartyStateDialog(
              onAccept: () => _arriveAtLocation(context),
              title: 'Check in?',
              content: const Text(
                  'An update about your arrival at the selected location will be posted to the feed'),
            ),
          );
        },
        icon: const Icon(Icons.play_circle_outline_rounded));
  }

  void _arriveAtLocation(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.displayName == null ||
        FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      showErrorSnackBar('Please select username first', context);
      return;
    }

    var locationId = locationProvider.rootLocation!.id!;

    // TODO: move createPost to backend
    UserService.updateUserRootLocation(locationId).then(
          (locationUpdated) {
        if (!locationUpdated) {
          showErrorSnackBar(
              'Could not update your location, please retry', context);
          return;
        }

        PostService.createPost(locationId, PostType.start, null).then(
              (postCreated) {
            if (!postCreated) {
              showErrorSnackBar('Could not post your location update', context);
              return;
            }

            userProvider.updateUser();
            locationProvider.loadRootLocation(locationId: locationId);
          },
        );
      },
    );
  }
}