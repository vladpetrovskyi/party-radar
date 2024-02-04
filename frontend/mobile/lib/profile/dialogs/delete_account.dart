import 'package:flutter/material.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/login/login_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete account?"),
      content: const Text("This action cannot be undone!"),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.close)),
        ElevatedButton(
            onPressed: () {
              UserService.deleteUser().then((isUserDeleted) {
                if (!isUserDeleted) {
                  _showErrorSnackBar('Could not delete account', context);
                  return;
                }
                SharedPreferences.getInstance()
                    .then((prefs) => prefs.remove('club'));
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginWidget(),
                  ),
                );
              });
            },
            child: const Icon(Icons.check))
      ],
    );
  }

  void _showErrorSnackBar(String? message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          message ?? 'Could not update user data',
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
