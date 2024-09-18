import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/providers/user_provider.dart';
import 'package:party_radar/screens/login_screen.dart';
import 'package:party_radar/screens/user_profile/dialogs/app_info_dialog.dart';
import 'package:party_radar/screens/user_profile/user_settings_screen.dart';
import 'package:provider/provider.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const AppInfoDialog(),
      ),
    ),
    actions: [_getSettingsButton(context), _getLogoutButton(context)],
  );
}

Widget _getSettingsButton(BuildContext context) => IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UserSettingsScreen(),
        ),
      ),
      icon: const Icon(Icons.settings),
    );

Widget _getLogoutButton(BuildContext context) => IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            buttonPadding: const EdgeInsets.all(5),
            title: const Text('Logout'),
            content: const Text('Do you really want to logout?'),
            actions: <Widget>[
              ElevatedButton(
                child: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Icon(Icons.check),
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );

void _logout(BuildContext context) {
  FirebaseMessaging.instance.deleteToken();
  Navigator.of(context).pop();
  FirebaseAuth.instance.signOut().then(
      (_) => Provider.of<UserProvider>(context, listen: false).updateUser());
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => const LoginScreen(),
    ),
  );
}
