import 'package:flutter/material.dart';
import 'package:party_radar/common/services/location_service.dart';
import 'package:party_radar/common/services/user_service.dart';

import 'models.dart';

class LocationProvider extends ChangeNotifier {
  Location? _rootLocation;
  bool editMode;
  List<int> currentLocationTree = <int>[];
  List<int?> lastOpenedExpansions = <int?>[];

  LocationProvider({this.editMode = false}) {
    loadRootLocation();
  }

  Location? get rootLocation => _rootLocation;

  Future<void> loadRootLocation({int? locationId, bool reloadCurrent = false}) async {
    if (reloadCurrent) {
      _rootLocation = await LocationService.getLocation(_rootLocation?.id);
    } else if (locationId != null) {
      _rootLocation = await LocationService.getLocation(locationId);
    } else {
      _rootLocation = await _loadRootLocationForUser();
    }
    notifyListeners();
  }

  void loadCurrentLocationTree() async {
    currentLocationTree = await LocationService.getSelectedLocationIds();
    notifyListeners();
  }

  Future<Location?> _loadRootLocationForUser() async =>
      await LocationService.getLocation(
          (await UserService.getUser())!.rootLocationId);

  void updateRootLocation(Location? rootLocation) {
    _rootLocation = rootLocation;
    notifyListeners();
  }

  void setEditMode(bool? val) {
    editMode = val ?? !editMode;
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  User? _user;

  UserProvider() {
    updateUser();
  }

  User? get user => _user;

  void updateUser() async {
    _user = await UserService.getUser();
  }
}
