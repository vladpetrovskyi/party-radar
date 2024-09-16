import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:party_radar/models/post.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/widgets/party_state_dialog.dart';
import 'package:party_radar/services/post_service.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';
import 'package:provider/provider.dart';

class ActionsWidget extends StatelessWidget with ErrorSnackBar {
  const ActionsWidget({
    super.key,
    required this.userProvider,
    required this.locationProvider,
  });

  final UserProvider userProvider;
  final LocationProvider locationProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [partyStateButton, editButton],
    );
  }

  Widget get partyStateButton {
    if (locationProvider.editMode) return Container();

    if (userProvider.user?.rootLocationId != null &&
        userProvider.user?.rootLocationId ==
            locationProvider.rootLocation?.id) {
      return _EndPartyButton(
          userProvider: userProvider, locationProvider: locationProvider);
    }

    return _StartPartyButton(
        userProvider: userProvider, locationProvider: locationProvider);
  }

  Widget get editButton => Padding(
        padding: const EdgeInsets.only(right: 6.60),
        child: userProvider.user?.username ==
                locationProvider.rootLocation?.createdBy
            ? IconButton(
                onPressed: () => locationProvider.setEditMode(null),
                icon: locationProvider.editMode
                    ? const Icon(Icons.check)
                    : const Icon(Icons.edit_outlined),
              )
            : Container(),
      );
}

class _StartPartyButton extends StatelessWidget with ErrorSnackBar {
  const _StartPartyButton(
      {required this.userProvider, required this.locationProvider});

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
    if (firebase.FirebaseAuth.instance.currentUser?.displayName == null ||
        firebase.FirebaseAuth.instance.currentUser!.displayName!.isEmpty) {
      showErrorSnackBar('Please select username first', context);
      return;
    }

    var locationId =
        Provider.of<LocationProvider>(context, listen: false).rootLocation!.id!;

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

            Provider.of<UserProvider>(context, listen: false).updateUser();
            Provider.of<LocationProvider>(context, listen: false)
                .loadRootLocation(locationId: locationId);
          },
        );
      },
    );
  }
}

class _EndPartyButton extends StatelessWidget with ErrorSnackBar {
  const _EndPartyButton(
      {required this.userProvider, required this.locationProvider});

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
