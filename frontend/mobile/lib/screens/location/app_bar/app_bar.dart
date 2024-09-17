import 'package:flutter/material.dart';
import 'package:party_radar/providers/location_provider.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/location/app_bar/widgets/actions/edit_location_button.dart';
import 'package:party_radar/screens/location/app_bar/widgets/actions/end_party_button.dart';
import 'package:party_radar/screens/location/app_bar/widgets/actions/start_party_button.dart';
import 'package:party_radar/screens/location/app_bar/widgets/title.dart';
import 'package:provider/provider.dart';

AppBar getAppBar(BuildContext context) {
  var locationProvider = Provider.of<LocationProvider>(context, listen: true);
  var userProvider = Provider.of<UserProvider>(context, listen: true);
  return AppBar(
    centerTitle: true,
    title: const AppBarTitle(),
    actions: locationProvider.rootLocation == null
        ? null
        : _getAppBarActions(locationProvider, userProvider),
  );
}

List<Widget> _getAppBarActions(
        LocationProvider locationProvider, UserProvider userProvider) =>
    [
      _getPartyStateButton(locationProvider, userProvider),
      _getEditButton(locationProvider, userProvider)
    ];

Widget _getPartyStateButton(
    LocationProvider locationProvider, UserProvider userProvider) {
  if (locationProvider.editMode) return Container();

  if (userProvider.user?.rootLocationId != null &&
      userProvider.user?.rootLocationId == locationProvider.rootLocation?.id) {
    return EndPartyButton(
        userProvider: userProvider, locationProvider: locationProvider);
  }

  return StartPartyButton(
      userProvider: userProvider, locationProvider: locationProvider);
}

Widget _getEditButton(
        LocationProvider locationProvider, UserProvider userProvider) =>
    Padding(
      padding: const EdgeInsets.only(right: 6.60),
      child: userProvider.user?.username ==
              locationProvider.rootLocation?.createdBy
          ? EditLocationButton(locationProvider: locationProvider)
          : Container(),
    );
