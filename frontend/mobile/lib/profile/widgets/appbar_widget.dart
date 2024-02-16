import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:party_radar/login/login_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: const Center(
                  child: Text(
                    'Infos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Legal:',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                        child: const Text('• Privacy policy',
                            style: TextStyle(fontSize: 16)),
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.party-radar.app/privacy-policy'))),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                        child: const Text(
                          '• Terms and conditions',
                          style: TextStyle(fontSize: 16),
                        ),
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.party-radar.app/terms-and-conditions'))),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Credits/Attributions:',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: InkWell(
                          child: const Text(
                              '• User icons created by kmg design - Flaticon',
                              style: TextStyle(fontSize: 16)),
                          onTap: () => launchUrl(Uri.parse(
                              'https://www.flaticon.com/free-icons/user'))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: InkWell(
                          child: const Text(
                            '• Radar icons created by Freepik - Flaticon',
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () => launchUrl(Uri.parse(
                              'https://www.flaticon.com/free-icons/radar'))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SimpleDialogOption(
                    child: const Center(
                      child: Text(
                        'SEND A FEEDBACK',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://www.party-radar.app/contact')),
                  ),
                  SimpleDialogOption(
                    child: const Center(
                      child: Text(
                        'REPORT AN ERROR',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://www.party-radar.app/contact')),
                  ),
                  SimpleDialogOption(
                    child: const Center(
                      child: Text(
                        'BACK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            });
      },
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
