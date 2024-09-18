import 'package:flutter/material.dart';
import 'package:party_radar/models/user.dart';
import 'package:party_radar/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  UserProvider() {
    updateUser();
  }

  User? get user => _user;

  void updateUser() async {
    _user = await UserService.getCurrentUser();
  }
}