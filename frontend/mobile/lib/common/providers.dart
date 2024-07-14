import 'package:flutter/material.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/common/services/user_service.dart';

import 'models.dart';

class LocationProvider extends ChangeNotifier {
  Location? rootLocation;
  bool editMode;

  LocationProvider({this.rootLocation, this.editMode = false});

  void updateLocation(int? locationId) async {
    int? userRootLocationId;
    if (locationId != null ||
        (userRootLocationId = (await UserService.getUser())?.rootLocationId) !=
            null) {
      var userLocation =
          await LocationService.getLocation(locationId ?? userRootLocationId);
      rootLocation = userLocation;
    } else {
      rootLocation = null;
    }
    notifyListeners();
  }

  void updateRootLocation(Location? rootLocation) {
    this.rootLocation = rootLocation;
    notifyListeners();
  }

  void setEditMode(bool? val) {
    editMode = val ?? !editMode;
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  User? user;
  List<int> currentLocationTree = <int>[];

  UserProvider({this.user}) {
    updateUser();
  }

  void updateUser() async {
    user = await UserService.getUser();
    currentLocationTree = await LocationService.getSelectedLocationIds();
    notifyListeners();
  }
}
