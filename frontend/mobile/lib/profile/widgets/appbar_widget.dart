import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/login/login_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: const IconButton(
      icon: Icon(Icons.question_mark_rounded),
      onPressed: null,
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  actionsAlignment: MainAxisAlignment.center,
                  buttonPadding: const EdgeInsets.all(5),
                  title: const Text('Logout'),
                  content: const Text('Do you really want to logout?'),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Icon(Icons.check),
                      onPressed: () {
                        SharedPreferences.getInstance()
                            .then((prefs) => prefs.remove('club'));
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginWidget(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              });
            },
          );
        },
      )
    ],
  );
}
